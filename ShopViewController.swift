import UIKit

class ShopViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var profile: PlayerProfile
    private let table = UITableView(frame: .zero, style: .insetGrouped)
    var onPurchase: ((PlayerProfile)->Void)? = nil

    // sample catalog
    private var items: [(id: String, name: String, price: Int, type: String)] = [
        ("plane_skin_1","Plane Skin 1",500,"skin"),
        ("bg_night","Night Background",400,"bg"),
        ("engine_l1","Engine L1 (+8%)",800,"upgrade")
    ]

    init(profile: PlayerProfile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Shop"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .close, target: self, action: #selector(close))
        table.delegate = self
        table.dataSource = self
        table.frame = view.bounds
        table.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(table)
        let header = UILabel(frame: CGRect(x:0,y:0,width:view.bounds.width,height:60))
        header.text = "Coins: \(profile.coins)"
        header.textAlignment = .center
        table.tableHeaderView = header
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    // MARK: - Table

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let it = items[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = it.name
        cell.detailTextLabel?.text = "\(it.price) coins"
        cell.accessoryType = .none
        if it.type == "skin" && profile.ownedSkins.contains(it.id) { cell.accessoryType = .checkmark }
        if it.type == "bg" && profile.ownedBackgrounds.contains(it.id) { cell.accessoryType = .checkmark }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let it = items[indexPath.row]
        if profile.coins < it.price {
            let a = UIAlertController(title: "Can't buy", message: "Not enough coins", preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
            return
        }
        profile.coins -= it.price
        if it.type == "skin" {
            if !profile.ownedSkins.contains(it.id) { profile.ownedSkins.append(it.id) }
            profile.selectedSkin = it.id
        } else if it.type == "bg" {
            if !profile.ownedBackgrounds.contains(it.id) { profile.ownedBackgrounds.append(it.id) }
            profile.selectedBackground = it.id
        } else if it.type == "upgrade" {
            profile.engineLevel += 1
        }
        Persistence.save(profile)
        table.reloadData()
        (table.tableHeaderView as? UILabel)?.text = "Coins: \(profile.coins)"
        // notify caller
        onPurchase?(profile)
    }
}
