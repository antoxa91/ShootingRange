//
//  GameScene.swift
//  ShootingRange
//
//  Created by Антон Стафеев on 16.09.2022.
//

import SpriteKit

final class GameScene: SKScene {
    var newGameLabel: SKLabelNode!
    var reloadLabel: SKLabelNode!
    var target: SKSpriteNode!
    var backgroundMusic: SKAudioNode!
    var scoreLabel: SKLabelNode!
    var score = 0 {
        didSet {
            scoreLabel.text = "Очки: \(score)"
        }
    }
    
    var gameOverLabel: SKSpriteNode!
    var isGameOver = true {
        willSet {
            if newValue {
                newGameLabel.alpha = 1
            } else {
                newGameLabel.alpha = 0
            }
        }
    }
    
    var timeLabel: SKLabelNode!
    var gameTimer: Timer?
    var seconds = 60 {
        willSet {
            timeLabel.text = "Секунд: \(newValue)"
        }
    }
    
    var shotsImage: SKSpriteNode!
    var shots = 3 {
        didSet {
            shotsImage.texture = SKTexture(imageNamed: "shots\(shots)")
        }
    }
    
    override func didMove(to view: SKView) {
        startingView(view)
        
        if let musicURL = Bundle.main.url(forResource: "music", withExtension: "mp3") {
            backgroundMusic = SKAudioNode(url: musicURL)
            addChild(backgroundMusic)
        }
    }
    
    
    @objc private func startGame() {
        gameOverLabel.alpha = 0
        seconds = 60
        shots = 3
        score = 0
        
        gameTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
    }
    
    @objc private func updateTime() {
        seconds -= 1
        spawnTarget()
        spawnTarget()
        
        switch seconds {
        case 0:
            gameTimer?.invalidate()
            isGameOver.toggle()
            gameOverLabel.run(SKAction.fadeIn(withDuration: 1.5))
            run(SKAction.playSoundFileNamed("gameOver", waitForCompletion: false))
            timeLabel.fontColor = .white
        case  ..<11: timeLabel.fontColor = .red
        case  ..<16: timeLabel.fontColor = .orange
        default:
            break
        }
    }
    
    private func spawnTarget() {
        guard !isGameOver else { return }
        
        if Int.random(in: 1...2) == 1 {
            let numline = Int.random(in: 1...3)
            
            switch numline {
            case 1: createTargets(y: 140)
            case 2: createTargets(y: 390)
            case 3: createTargets(y: 680)
            default:
                break
            }
        }
    }
    
    private func createTargets(y: Int) {
        let randomTarget = Int.random(in: 0...2)
        
        guard let posX = [0, 1000].randomElement() else { return }
        var moveToX: CGFloat
        if posX == 0 {
            moveToX = 1200
        } else {
            moveToX = -200
        }
        
        switch randomTarget {
        case 0:
            target = SKSpriteNode(imageNamed: "targetBomb")
            target.name = "targetBomb"
            posAndMoving(positionX: posX, positionY: y,
                         moveToX: moveToX, duration: 3)
        case 1:
            target = SKSpriteNode(imageNamed: "targetSlow")
            target.name = "targetSlow"
            posAndMoving(positionX: posX, positionY: y,
                         moveToX: moveToX, duration: 3)
        case 2:
            target = SKSpriteNode(imageNamed: "targetFast")
            target.name = "targetFast"
            posAndMoving(positionX: posX, positionY: y,
                         moveToX: moveToX, duration: 2)
        default:
            break
        }
        
        target.zPosition = 3
        addChild(target)
    }
    
    private func posAndMoving(positionX: Int, positionY: Int,
                              moveToX: CGFloat, duration: TimeInterval) {
        target.position = CGPoint(x: positionX, y: positionY)
        let moving = SKAction.moveTo(x: moveToX, duration: duration)
        target.run(moving)
    }
    
    override func update(_ currentTime: TimeInterval) {
        for node in children {
            if node.position.x < -100 {
                node.removeFromParent()
            } else if node.position.x > 1199 {
                node.removeFromParent()
            }
        }
    }
    
    // MARK: - Touching
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNodes = nodes(at: location)
        
        if tappedNodes.contains(where: { $0.name == "playGame" }) {
            startGame()
            isGameOver.toggle()
            speed = 1
            return
        }
        
        if tappedNodes.contains(where: { $0.name == "reload" }) {
            run(SKAction.playSoundFileNamed("reload", waitForCompletion: false))
            shots = 3
        } else {
            if shots > 0 {
                run(SKAction.playSoundFileNamed("shot", waitForCompletion: false))
                shots -= 1
            } else {
                return
            }
        }
        
        targetTapped(tappedNodes)
    }
    
    private func targetTapped(_ tappedNodes: [SKNode]) {
        for node in tappedNodes {
            switch node.name {
            case "targetBomb":
                if let explosion = SKEmitterNode(fileNamed: "explosion") {
                    explosion.position = node.position
                    addChild(explosion)
                }
                destroyNode(node, soundName: "boom")
                score -= 500
                speed -= 0.05
            case "targetSlow":
                destroyNode(node, soundName: "hit")
                score += 100
                speed += 0.03
            case "targetFast":
                destroyNode(node, soundName: "hit2")
                score += 200
                speed += 0.05
            case "rocks": return
            default:
                break
            }
        }
    }
    
    private func destroyNode(_ node: SKNode, soundName: String) {
        node.removeAllActions()
        node.run(SKAction.fadeOut(withDuration: 0.3))
        run(SKAction.playSoundFileNamed(soundName, waitForCompletion: false))
    }
}


// MARK: - Start Scene
extension GameScene {
    private func startingView(_ view: SKView) {
        let background = SKSpriteNode(imageNamed: "spaceBackground")
        background.blendMode = .replace
        background.position = CGPoint(x: 512, y: 384)
        background.zPosition = -1
        background.size = view.frame.size
        addChild(background)
        
        timeLabel = SKLabelNode(fontNamed: "Noteworthy")
        timeLabel.position = CGPoint(x: 130, y: 700)
        timeLabel.zPosition = 101
        timeLabel.text = "Секунд: 60"
        timeLabel.fontSize = 44
        addChild(timeLabel)
        
        newGameLabel = SKLabelNode(fontNamed: "Noteworthy")
        newGameLabel.fontColor = .green
        newGameLabel.zPosition  = 101
        newGameLabel.position = CGPoint(x: 512, y: 700)
        newGameLabel.fontSize = 44
        newGameLabel.text = "Новая игра"
        newGameLabel.name = "playGame"
        newGameLabel.alpha = 1
        addChild(newGameLabel)
        
        scoreLabel = SKLabelNode(fontNamed: "Noteworthy")
        scoreLabel.position = CGPoint(x: 1000, y: 700)
        scoreLabel.zPosition = 101
        scoreLabel.fontSize = 44
        scoreLabel.text = "Очков: 0"
        scoreLabel.horizontalAlignmentMode = .right
        addChild(scoreLabel)
        
        shotsImage = SKSpriteNode(imageNamed: "shots\(shots)")
        shotsImage.zPosition = 101
        shotsImage.position = CGPoint(x: 440, y: 45)
        addChild(shotsImage)
        
        reloadLabel = SKLabelNode(fontNamed: "Noteworthy")
        reloadLabel.zPosition = 101
        reloadLabel.position = CGPoint(x: 580, y: 35)
        reloadLabel.fontSize = 22
        reloadLabel.text = "ПЕРЕЗАРЯДИТЬ!"
        reloadLabel.name = "reload"
        addChild(reloadLabel)
        
        gameOverLabel = SKSpriteNode(imageNamed: "gameOver")
        gameOverLabel.zPosition = 101
        gameOverLabel.position = CGPoint(x: 512, y: 384)
        gameOverLabel.alpha = 0
        addChild(gameOverLabel)
        
        createRocks()
        createRocks()
        createRocks()
    }
    
    private func createRocks() {
        let rocks = SKSpriteNode(imageNamed: "rocks")
        rocks.name = "rocks"
        rocks.zPosition = 10
        rocks.position = CGPoint(x: Int.random(in: 50...900),
                                 y: Int.random(in: 50...700))
        addChild(rocks)
    }
}
