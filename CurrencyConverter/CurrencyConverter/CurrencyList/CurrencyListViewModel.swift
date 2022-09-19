//
//  CurrencyListViewModel.swift
//  CurrencyConverter
//


import Foundation
import CoreData

class CurrencyListViewModel {
    
    private var isFetching:Bool = false
    
    private let api:WebServiceManager
    private var onReloadVisibleData:(() -> Void)?
    private var onError:((Error) -> Void)?
    
    private var fetchedResultsController: NSFetchedResultsController<Currency>
    private let managedObjectContext:NSManagedObjectContext
    private var fetchResultDelegateWrapper:NSFetchedResultsControllerDelegateWrapper
    
    init(
        api:WebServiceManager,
        managedObjectContext:NSManagedObjectContext,
        onWillChangeContent:(() -> Void)? = nil,
        onChange:((
            _ indexPath:IndexPath?,
            _ type: NSFetchedResultsChangeType?,
            _ newIndexPath:IndexPath?) -> Void)? = nil,
        onDidChangeContent:(() -> Void)? = nil,
        onReloadVisibleData:(() -> Void)?,
        onError:((Error) -> Void)? = nil) {
            
            self.api = api
            self.managedObjectContext = managedObjectContext
            self.onReloadVisibleData = onReloadVisibleData
            self.onError = onError
            
            fetchResultDelegateWrapper = NSFetchedResultsControllerDelegateWrapper(
                onWillChangeContent: onWillChangeContent,
                onDidChangeContent: onDidChangeContent,
                onChange: onChange)
            
            // Configure Fetch Request
            let fetchRequest: NSFetchRequest<Currency> = Currency.fetchRequest()
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
    
    func fetchCurrencies(_ completion: (() -> Void)? = nil) {
        if isFetching { return }
        isFetching = true
        api.fetchCurrencies() {[weak self] (result) in
            guard let weakSelf = self else { return }
            
            switch result {
            case .success(let value):
                let context = weakSelf.managedObjectContext
                context.mergePolicy = NSMergePolicy.overwrite
                context.perform {
                    do {
                        value.forEach {
                            let c = Currency(ctx: context)
                            c.code = $0.key
                            c.name = $0.value
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
    
    func currency(at indexPath:IndexPath) -> Currency? {
        let result:NSFetchRequestResult = fetchedResultsController.object(at: indexPath)
        return result as? Currency
    }
}

extension CurrencyListViewModel {
    
    /// Filtering the Currency list.
    ///
    /// - Parameters:
    ///   - text
    ///   - completion
    func filter(text: String = "") {
        
        if text.count > 0 {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(searchText: text)
        }
        else{
            
            fetchedResultsController.fetchRequest.predicate = nil
        }
        
        do {
            try fetchedResultsController.performFetch()
            onReloadVisibleData?()
        } catch {
            onError?(error)
        }
    }
}


