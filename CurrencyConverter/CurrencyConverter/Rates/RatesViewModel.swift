//
//  CCRatesViewModel.swift
//  CurrencyConverter
//

import Foundation

import CoreData

class RatesViewModel {
    
    let title = "Rates"
    
    private var isFetching:Bool = false
    private var newRequestWaitingTime:Double // In seconds
    
    private let api:WebServiceManager
    private var onError:((Error) -> Void)?
    private var onReloadVisibleData:(() -> Void)?
    private var onDidReceiveUpdatedData:(() -> Void)?
    
    private var fetchedResultsController: NSFetchedResultsController<Rate>
    private let managedObjectContext:NSManagedObjectContext
    private let defaults:AppDefaultsAdditions
    
    private var fetchResultDelegateWrapper:NSFetchedResultsControllerDelegateWrapper
    
    private var referenceValue:Decimal = 1.0
    
    private var lastTriedCodeToExecute:String? = nil // For retry()
    
    private var baseRateSelected:Rate?
    
    init(
        api:WebServiceManager,
        managedObjectContext:NSManagedObjectContext,
        defaults:AppDefaultsAdditions,
        newRequestWaitingTime:Double = 29 * 60, // Default is 30 Minutes
        onDidReceiveUpdatedData:(() -> Void)? = nil, // Data comes from server
        onWillChangeContent:(() -> Void)? = nil,
        onChange:((
        _ indexPath:IndexPath?,
        _ type: NSFetchedResultsChangeType?,
        _ newIndexPath:IndexPath?) -> Void)? = nil,
        onDidChangeContent:(() -> Void)? = nil,
        onReloadVisibleData:(() -> Void)? = nil,
        onError:((Error) -> Void)? = nil) {
        
        self.api = api
        self.managedObjectContext = managedObjectContext
        self.defaults = defaults
        self.newRequestWaitingTime = newRequestWaitingTime
        self.onReloadVisibleData = onReloadVisibleData
        self.onDidReceiveUpdatedData = onDidReceiveUpdatedData
        self.onError = onError
        
        fetchResultDelegateWrapper = NSFetchedResultsControllerDelegateWrapper(
            onWillChangeContent: onWillChangeContent,
            onDidChangeContent: onDidChangeContent,
            onChange: onChange)
        
        // Configure Fetch Request
        let fetchRequest: NSFetchRequest<Rate> = Rate.fetchRequest()
        
        fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        fetchedResultsController.delegate = fetchResultDelegateWrapper
        do {
            try fetchedResultsController.performFetch()
        } catch {
            self.onError?(error)
        }
    }
    
    
    /// Refresh Decides if the request will execute or not.
    ///
    /// - Parameter completion
    func refresh(_ completion: ((_ hasExcuted: Bool) -> Void)? = nil) {
        // check for the lastFetchTimestamp.
        if let _lastFetch = defaults.get(for: .lastFetchTimestamp) as Date?, Date().timeIntervalSince(_lastFetch) < newRequestWaitingTime {
            // the request was not executed, because we avoid to reach
            // the request rate limitation.
            
            //print("Checking values")
            // print(Date().timeIntervalSince(_lastFetch))
            // print(newRequestWaitingTime)
            
            completion?(false)
            return
        }
        
        fetchRates(code: baseCurrencyCode()) {
            DispatchQueue.main.async {
                print("Refreshed")
                
                completion?(true)
            }
        }
    }
    
    /// Retry to fetchRates request()
    func retry() {
        guard let code = lastTriedCodeToExecute else { return }
        fetchRates(code: code)
    }
    
    /// Fetch The Rate of certain code.
    ///
    /// - Parameters:
    ///   - code
    ///   - completion
    func fetchRates(code:String, _ completion: (() -> Void)? = nil) {
        
        // Now We only fetching USD rates
        
        //let freeVersionCode = "USD"
        
        if isFetching { return }
        isFetching = true
        lastTriedCodeToExecute = code
        api.fetchLive(source: code) {[weak self] (result) in
            guard let weakSelf = self else { return }
            
            switch result {
            case .success(let value):
                
                // Delete the lastTriedCode, since we don't need to retry() the request.
                weakSelf.lastTriedCodeToExecute = nil
                
                // Let's check if it has previous data, so we can add a default value if none.
                let needToAddDefaultCurrencyList = weakSelf.defaults.get(for: .lastQuotesTimestamp) == nil
                
                // Must set to value.timestamp for the lastQuotesTimestamp
                weakSelf.defaults.set(value: value.timestamp, for: .lastQuotesTimestamp)
                
                // Let's set the actual base currency now, since we finally get a valid one.
                weakSelf.defaults.set(value: value.base, for: .baseCurrencyCode)
                
                
                if let onDidReceiveUpdatedData = weakSelf.onDidReceiveUpdatedData {
                    DispatchQueue.main.async {
                        onDidReceiveUpdatedData()
                    }
                }
                
                let context = weakSelf.managedObjectContext
                
                context.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
                context.perform {
                    do {
                        value.rates.forEach {
                            let currencyCode = String($0.key.suffix(3))
                            let r = Rate.findOrCreate(currencyCode: currencyCode, in: context)
                            // code will be like Source-Target like `USDGBP`
                            // so let's clean the data before saving to our database since we only support 1 base currency conversion at a time
                            r.currencyCode = String($0.key.suffix(3))
                            r.value = NSDecimalNumber(floatLiteral: $0.value)
                            if needToAddDefaultCurrencyList {
                                r.active = true
                            }
                        }
                        try context.save()
                    } catch {
                        if let onError = weakSelf.onError {
                            DispatchQueue.main.async {
                                onError(error)
                            }
                        }
                    }
                }
                
                // Must set to now the lastFetchtimestamp
                weakSelf.defaults.set(value: Date(), for: .lastFetchTimestamp)
                
            case .failure(let error):
                if let onError = weakSelf.onError {
                    DispatchQueue.main.async {
                        onError(error)
                    }
                }
            }
            weakSelf.isFetching = false
            completion?()
        }
    }
    
    var numberOfItems:Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    var numberOfSections:Int {
        return 1
    }
    
    /// The Rate at indexPath.
    ///
    /// - Parameter indexPath
    /// - Returns Rate
    func rate(at indexPath:IndexPath) -> Rate? {
        let result:NSFetchRequestResult = fetchedResultsController.object(at: indexPath)
        return result as? Rate
    }
    
    
    
    
    /// Get the Equivalent Rate of the Base Currency in other currencies.
    ///
    /// - Parameter indexPath
    /// - Returns: CalculatedRate?
    func item(at indexPath:IndexPath) -> CalculatedRate? {
        guard let obj = rate(at: indexPath) else { return nil }
        
        // let calculatedBaseValue = baseCurrencyMultiplier() * Double(truncating: referenceValue as NSNumber)  // Local Currency Change
        
        return obj.equivalentRate(at: NSDecimalNumber(decimal: referenceValue))
    }
    
    
    /// Get the Base Currency Code
    ///
    /// - Returns: String
    func baseCurrencyCode() -> String {
        return defaults.get(for: .baseCurrencyCode) ?? "USD"
    }
    
    
    /// Get currency multiplier for local
    ///
    /// - Returns: Double
    //    func baseCurrencyMultiplier() -> Double {
    //        return defaults.get(for: .baseCurrencyMultiplier) ?? 1.0
    //    }
}

// MARK: - Other Actions
extension RatesViewModel {
    
    /// Update the Reference value (of the Base currency)
    ///
    /// - Parameter referenceValue
    func update(referenceValue: Decimal) {
        self.referenceValue = referenceValue
        // No need to hit the server we just have to update the visible data.
        onReloadVisibleData?()
    }
    
    /// Update the Base Currency Code
    ///
    /// - Parameter baseCurrencyCode
    func update(baseCurrencyCode: String) {
        // Need to update the data from server,
        fetchRates(code: baseCurrencyCode) // For Paid API
        
        //  self.updateBaseCurrencyLocal(baseCurrencyCode: baseCurrencyCode)
        
    }
    
    
    /// Function to change Base Currency locally
    ///
    /// - Parameters:
    ///   - baseCurrencyCode: baseCurrencyCode
    ///   - completion: completion description
    func updateBaseCurrencyLocal(baseCurrencyCode: String){
        
        if baseCurrencyCode == "USD"{
            
            self.defaults.set(value: 1.0, for: .baseCurrencyMultiplier)
            
            self.defaults.set(value: "USD", for: .baseCurrencyCode) //change Base Currency
            self.onReloadVisibleData?()
            
        }
        else{
            
            
        }
        //self.baseRateSelected?.active = true
        
        managedObjectContext.perform { [weak self] in
            do {
                guard let context = self?.managedObjectContext,
                    let rate = Rate.find(currencyCode: baseCurrencyCode, in: context)
                    else { return }
                
                // rate.active = false
                try context.save()
                if let val = rate.value{
                    
                    let multi = 1 / val.doubleValue
                    //let decimal = Decimal(floatLiteral: multi)
                    
                    self?.defaults.set(value: multi, for: .baseCurrencyMultiplier)
                }
                self?.defaults.set(value: baseCurrencyCode, for: .baseCurrencyCode) //change Base Currency
                self?.baseRateSelected = rate
                //completion?()
                self?.onReloadVisibleData?()
                
            } catch {
                if let onError = self?.onError {
                    DispatchQueue.main.async {
                        onError(error)
                    }
                }
            }
        }
        
    }
}
