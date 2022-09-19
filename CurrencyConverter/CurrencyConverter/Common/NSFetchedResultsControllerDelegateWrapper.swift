//
//  NSFetchedResultsControllerDelegateWrapper.swift
//  CurrencyConverter

import Foundation
import CoreData

/// NSFetchedResultsControllerDelegateWrapper is a wrapper that will help to avoid repeatition on setting up the NSFetchResultControllerDelegate
class NSFetchedResultsControllerDelegateWrapper:NSObject, NSFetchedResultsControllerDelegate {
    
    private var onWillChangeContent:(() -> Void)?
    private var onDidChangeContent:(() -> Void)?
    private var onChange:((
    _ indexPath:IndexPath?,
    _ type: NSFetchedResultsChangeType,
    _ newIndexPath:IndexPath?) -> Void)?
    
    init(
        onWillChangeContent:(() -> Void)?,
        onDidChangeContent:(() -> Void)?,
        onChange:((
        _ indexPath:IndexPath?,
        _ type: NSFetchedResultsChangeType,
        _ newIndexPath:IndexPath?) -> Void)?) {
        self.onWillChangeContent = onWillChangeContent
        self.onDidChangeContent = onDidChangeContent
        self.onChange = onChange
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.onWillChangeContent?()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.onDidChangeContent?()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any, at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        self.onChange?(indexPath, type, newIndexPath)
    }
}
