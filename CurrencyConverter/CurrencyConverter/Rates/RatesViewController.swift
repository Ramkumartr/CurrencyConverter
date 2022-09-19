//
//  ViewController.swift
//  CurrencyConverter

import UIKit
import CoreData

class RatesViewController:UIViewController {
    
    @IBOutlet weak var tableView:UITableView!
    @IBOutlet weak var inputField:UITextField!
    @IBOutlet weak var currencyButton:UIButton!
    var refreshTimer: Timer?
    
    lazy var viewModel:RatesViewModel = {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("AppDelegate must not be null!")
        }
        return RatesViewModel(
            api: WebServiceManager.shared,
            managedObjectContext: appDelegate.persistentContainer.viewContext,
            defaults: AppDefaults.shared,
            onDidReceiveUpdatedData: {[weak self] in
                self?.currencyButton.setTitle(self?.viewModel.baseCurrencyCode(), for: .normal)
                
            },
            onWillChangeContent: { [weak self] in
                self?.tableView.beginUpdates()
            },
            onChange: { [weak self] (indexPath, type, newIndexPath) in
                guard let weakSelf = self, let _type = type else { return }
                switch (_type) {
                case .insert:
                    guard let _newIndexPath = newIndexPath else { return }
                    weakSelf.tableView.insertRows(at: [_newIndexPath], with: .fade)
                case .update:
                    guard let _indexPath = indexPath else { return }
                    weakSelf.tableView.reloadRows(at: [_indexPath], with: .fade)
                case .delete:
                    guard let _indexPath = indexPath else { return }
                    weakSelf.tableView.deleteRows(at: [_indexPath], with: .fade)
                case .move:
                    guard let _indexPath = indexPath, let _newIndexPath = newIndexPath else { return }
                    weakSelf.tableView.moveRow(at: _indexPath, to: _newIndexPath)
                default:
                    break
                }
            },
            onDidChangeContent: { [weak self] in
                self?.tableView.endUpdates()
            },
            onReloadVisibleData: { [weak self] in
                self?.tableView.reloadData()
                self?.currencyButton.setTitle(self?.viewModel.baseCurrencyCode(), for: .normal)
            },
            onError:  {[weak self] error in
                guard let weakSelf = self else { return }
                
                weakSelf.showAlert(error: error)
                
        })
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = viewModel.title
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(
            self, action: #selector(RatesViewController.refresh(_:)),
            for: .valueChanged)
        
        tableView.rowHeight = 70
        tableView.register(RateTableViewCell.self)
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.refreshControl = refreshControl
        
        
        currencyButton.setTitle(viewModel.baseCurrencyCode(), for: .normal)
        currencyButton.layer.cornerRadius = 10.0
        currencyButton.layer.borderWidth = 1.0
        currencyButton.layer.borderColor = UIColor.black.cgColor
        currencyButton.addTarget(
            self, action: #selector(RatesViewController.changeBaseCurrency),
            for: .touchUpInside)
        
        inputField.delegate = self
        inputField.text = "1.00"
        inputField.keyboardType = .decimalPad
        inputField.addTarget(self, action: #selector(RatesViewController.textFieldDidChange(_:)), for: .editingChanged)
        
        if refreshTimer == nil {
            
            refreshTimer = Timer.scheduledTimer(timeInterval: 30 * 60, target: self, selector: #selector(refresh), userInfo: nil, repeats: true)
        }
        
        refresh()
    }
    
    deinit {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    
}

// MARK: - Actions that can be done by the User
extension RatesViewController:UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard !string.isEmpty else {
            return true
        }
        
        let currentText = textField.text ?? ""
        let replacementText = (currentText as NSString).replacingCharacters(in: range, with: string)
        
        return replacementText.isDecimal()
    }
    
    
    @objc func textFieldDidChange(_ textField:UITextField) {
        guard let text = textField.text else { return }
        viewModel.update(referenceValue: Decimal(string: text) ?? 0.0)
    }
    
    @objc func refresh(_ sender: UIRefreshControl? = nil) {
        viewModel.refresh() { _ in
            
            if let sndr = sender, sndr.isKind(of: UIRefreshControl.self) {
                sender?.endRefreshing()
            }
        }
    }
    
    
    @objc func changeBaseCurrency() {
        let currenciesVC = CurrencyListViewController()
        currenciesVC.delegate = self
        present(UINavigationController(rootViewController: currenciesVC),
                animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource
extension RatesViewController:UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    
    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell:RateTableViewCell = tableView.dequeue(RateTableViewCell.self)!
        guard let rate = viewModel.item(at: indexPath)
            else { return UITableViewCell() }
        cell.setValue(data: rate)
        return cell
    }
}



// MARK: - CurrenciesViewControllerDelegate
extension RatesViewController:CurrencyListViewControllerDelegate {
    
    
    func currencyListVC(_ currenciesVC:CurrencyListViewController, didSelect currency:Currency) {
        
        guard let _code = currency.code else { return }
        
        currenciesVC.navigationController?.dismiss(animated: true) {[weak self] in
            
            self?.viewModel.update(baseCurrencyCode: _code)
        }
    }
    
    func currencyListVCDidCancel(_ currenciesVC:CurrencyListViewController) {
        currenciesVC.dismiss(animated: true, completion: nil)
        
        
    }
    
}

extension RatesViewController:AlertShowable {
    
    func showAlert(error: Error){
        
        self.showAlert(
            title: "Error",
            message: "\(error)",
            actions: [
                UIAlertAction(title: "Cancel", style: .cancel, handler: nil),
                UIAlertAction(
                    title: "Retry",
                    style: .default,
                    handler: { (action) in
                        self.viewModel.retry()
                        
                }),
            ])
    }
}
