import SpriteKit
import AVFoundation

struct PlayerProfile: Codable {
    var coins: Int
    var bestMultiplier: Double
    var ownedSkins: [String]
    var selectedSkin: String
    var ownedBackgrounds: [String]
    var selectedBackground: String
    var engineLevel: Int
    var stabilityLevel: Int
}

class Persistence {
    private static let key = "crush_player_profile_v3"
    static func save(_ p: PlayerProfile) {
        if let d = try? JSONEncoder().encode(p) {
            UserDefaults.standard.set(d, forKey: key)
        }
    }
    static func load() -> PlayerProfile {
        if let d = UserDefaults.standard.data(forKey: key),
           let p = try? JSONDecoder().decode(PlayerProfile.self, from: d) {
            return p
        }
        return PlayerProfile(coins: 1000,
                             bestMultiplier: 1.0,
                             ownedSkins: ["plane_default"],
                             selectedSkin: "plane_default",
                             ownedBackgrounds: ["bg_day"],
                             selectedBackground: "bg_day",
                             engineLevel: 0,
                             stabilityLevel: 0)
    }
}

class GameScene: SKScene {

    // UI
    private var planeNode: SKSpriteNode!
    private var bgNode: SKSpriteNode!
    private var startButton: SKSpriteNode!
    private var cashoutButton: SKSpriteNode!
    private var shopButton: SKSpriteNode!
    private var multiplierLabel: SKLabelNode!
    private var balanceLabel: SKLabelNode!
    private var betLabel: SKLabelNode!

    // state
    private var profile: PlayerProfile!
    private var isRoundActive = false
    private var currentMultiplier: Double = 1.0
    private var crashMultiplier: Double = 1.0
    private var lastUpdateTime: TimeInterval = 0
    private var betAmount: Int = 100
    private var growthRate: Double = 0.6
    private var audioPlayer: AVAudioPlayer?

    override func didMove(to view: SKView) {
        profile = Persistence.load()
        setupUI()
        updateLabels()
        NotificationCenter.default.addObserver(self, selector: #selector(shopPurchase(_:)), name: NSNotification.Name("ShopPurchase"), object: nil)
    }

    private func setupUI() {
        backgroundColor = .black
        bgNode = SKSpriteNode(imageNamed: profile.selectedBackground)
        bgNode.size = size
        bgNode.position = CGPoint(x: size.width/2, y: size.height/2)
        bgNode.zPosition = -10
        addChild(bgNode)

        planeNode = SKSpriteNode(imageNamed: profile.selectedSkin)
        planeNode.position = CGPoint(x: size.width * 0.22, y: size.height * 0.35)
        planeNode.setScale(0.9)
        addChild(planeNode)

        multiplierLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        multiplierLabel.fontSize = 42
        multiplierLabel.position = CGPoint(x: size.width * 0.62, y: size.height * 0.72)
        multiplierLabel.zPosition = 50
        addChild(multiplierLabel)

        balanceLabel = SKLabelNode(fontNamed: "Menlo")
        balanceLabel.fontSize = 20
        balanceLabel.position = CGPoint(x: 24 + 80, y: size.height - 36)
        balanceLabel.horizontalAlignmentMode = .left
        addChild(balanceLabel)

        betLabel = SKLabelNode(fontNamed: "Menlo")
        betLabel.fontSize = 20
        betLabel.position = CGPoint(x: size.width - 120, y: size.height - 36)
        betLabel.horizontalAlignmentMode = .right
        addChild(betLabel)

        startButton = SKSpriteNode(imageNamed: "btn_start")
        startButton.name = "startButton"
        startButton.position = CGPoint(x: size.width * 0.62, y: 110)
        addChild(startButton)

        cashoutButton = SKSpriteNode(imageNamed: "btn_cashout")
        cashoutButton.name = "cashoutButton"
        cashoutButton.position = CGPoint(x: size.width * 0.78, y: 110)
        cashoutButton.isHidden = true
        addChild(cashoutButton)

        shopButton = SKSpriteNode(imageNamed: "icon_shop")
        shopButton.name = "shopButton"
        shopButton.position = CGPoint(x: size.width - 50, y: 50)
        addChild(shopButton)
    }

    private func updateLabels() {
        balanceLabel.text = "Coins: \(profile.coins)"
        betLabel.text = "Bet: \(betAmount)"
        multiplierLabel.text = "1.00x"
    }

    private func startRound() {
        guard !isRoundActive else { return }
        guard profile.coins >= betAmount else { showMessage("Not enough coins"); return }

        profile.coins -= betAmount
        Persistence.save(profile)
        updateLabels()

        isRoundActive = true
        currentMultiplier = 1.0
        multiplierLabel.text = "1.00x"
        lastUpdateTime = 0

        crashMultiplier = sampleCrashMultiplier()
        if crashMultiplier < 1.0 { crashMultiplier = 1.0 }

        planeNode.position = CGPoint(x: size.width * 0.22, y: size.height * 0.35)
        cashoutButton.isHidden = false
        startButton.isHidden = true

        playSound(named: "start.wav")
        runStartAnimation()
    }

    private func cashOut() {
        guard isRoundActive else { return }
        isRoundActive = false
        cashoutButton.isHidden = true
        startButton.isHidden = false

        let win = Int(Double(betAmount) * currentMultiplier)
        profile.coins += win
        if currentMultiplier > profile.bestMultiplier { profile.bestMultiplier = currentMultiplier }
        Persistence.save(profile)
        updateLabels()
        showWinEffect()
        showMessage("Cashed out: \(win) coins")
        playSound(named: "win.wav")
    }

    private func endRoundCrashed() {
        isRoundActive = false
        cashoutButton.isHidden = true
        startButton.isHidden = false
        showCrashEffect()
        showMessage("Crashed at \(String(format: "%.2f", crashMultiplier))x")
        playSound(named: "crash.wav")
    }

    override func update(_ currentTime: TimeInterval) {
        if lastUpdateTime == 0 { lastUpdateTime = currentTime }
        let dt = currentTime - lastUpdateTime
        lastUpdateTime = currentTime

        guard isRoundActive else { return }

        let engineBoost = 1.0 + Double(profile.engineLevel) * 0.08
        let eff = growthRate * engineBoost
        let incr = 1.0 + eff * dt
        currentMultiplier = currentMultiplier * incr

        animatePlane(for: currentMultiplier)
        multiplierLabel.text = String(format: "%.2fx", currentMultiplier)

        if currentMultiplier >= crashMultiplier { endRoundCrashed() }
    }

    private func sampleCrashMultiplier() -> Double {
        let alpha = 1.6
        let xm = 1.0
        let u = Double.random(in: 0.0001...0.9999)
        let x = xm / pow(u, 1.0/alpha)
        return min(x, 10_000.0)
    }

    private func animatePlane(for multiplier: Double) {
        let minY = size.height * 0.25
        let maxY = size.height * 0.88
        let t = log(1 + multiplier) / log(1 + 200)
        let clamped = max(0.0, min(1.0, t))
        let newY = minY + CGFloat(clamped) * (maxY - minY)
        planeNode.run(SKAction.moveTo(y: newY, duration: 0.12))
        planeNode.zRotation = CGFloat(min(0.6, 0.015 * multiplier))
    }

    // Programmatic crash emitter
    private func showCrashEffect() {
        let node = SKEmitterNode()
        node.particleTexture = SKTexture(imageNamed: "spark")
        node.particleBirthRate = 300
        node.numParticlesToEmit = 120
        node.particleLifetime = 1.2
        node.particleSpeed = 200
        node.particleSpeedRange = 80
        node.emissionAngleRange = CGFloat.pi * 2
        node.particleAlpha = 0.9
        node.particleAlphaRange = 0.2
        node.particleScale = 0.06
        node.particleScaleRange = 0.03
        node.position = planeNode.position
        node.zPosition = 100
        addChild(node)
        node.run(SKAction.sequence([SKAction.wait(forDuration: 1.4), SKAction.removeFromParent()]))
    }

    private func showWinEffect() {
        let flash = SKShapeNode(rectOf: CGSize(width: size.width*0.9, height: 60), cornerRadius: 8)
        flash.fillColor = .white
        flash.alpha = 0.0
        flash.position = CGPoint(x: size.width/2, y: size.height*0.6)
        addChild(flash)
        flash.run(SKAction.sequence([SKAction.fadeAlpha(to: 0.6, duration: 0.12),
                                     SKAction.wait(forDuration: 0.18),
                                     SKAction.fadeOut(withDuration: 0.18),
                                     SKAction.removeFromParent()]))
    }

    private func runStartAnimation() {
        let pulse = SKAction.sequence([SKAction.scale(to: 0.8, duration: 0.06),
                                       SKAction.scale(to: 0.95, duration: 0.06)])
        planeNode.run(SKAction.repeat(pulse, count: 3))
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let t = touches.first else { return }
        let loc = t.location(in: self)
        let nodesAt = nodes(at: loc)
        for node in nodesAt {
            if node.name == "startButton" { startRound(); return }
            if node.name == "cashoutButton" { cashOut(); return }
            if node.name == "shopButton" { openShop(); return }
        }
        if isRoundActive { cashOut() }
    }

    private func openShop() {
        // Present ShopViewController modally using UIKit bridge
        if let vc = view?.window?.rootViewController {
            let shop = ShopViewController(profile: profile)
            shop.modalPresentationStyle = .pageSheet
            shop.onPurchase = { [weak self] updatedProfile in
                guard let self = self else { return }
                self.profile = updatedProfile
                Persistence.save(self.profile)
                self.updateLabels()
            }
            vc.present(shop, animated: true)
        }
    }

    @objc private func shopPurchase(_ n: Notification) {
        // handle purchases coming from other parts if needed
        if let info = n.userInfo as? [String: Any],
           let key = info["item"] as? String,
           let price = info["price"] as? Int {
            if profile.coins >= price {
                profile.coins -= price
                if key.hasPrefix("bg_") {
                    if !profile.ownedBackgrounds.contains(key) { profile.ownedBackgrounds.append(key) }
                } else if key.hasPrefix("plane_") {
                    if !profile.ownedSkins.contains(key) { profile.ownedSkins.append(key) }
                }
                Persistence.save(profile)
                updateLabels()
            } else {
                showMessage("Not enough coins")
            }
        }
    }

    private func showMessage(_ text: String) {
        let label = SKLabelNode(fontNamed: "Menlo-Bold")
        label.text = text
        label.fontSize = 20
        label.position = CGPoint(x: size.width/2, y: size.height*0.55)
        addChild(label)
        label.run(SKAction.sequence([SKAction.wait(forDuration: 1.2), SKAction.fadeOut(withDuration: 0.4), SKAction.removeFromParent()]))
    }

    // Simple sound loader
    private func playSound(named: String) {
        guard let url = Bundle.main.url(forResource: named, withExtension: nil) else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            // ignore
        }
    }
}
