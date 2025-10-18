import AVFoundation
var backgroundMusicPlayer: AVAudioPlayer?

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    var bird: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    var score = 0
    var gameOver = false
    var gameOverLabel: SKLabelNode!
    var restartButton: SKLabelNode!

    struct PhysicsCategory {
        static let bird: UInt32 = 0x1 << 0
        static let pipe: UInt32 = 0x1 << 1
        static let scoreZone: UInt32 = 0x1 << 2
    }

    override func didMove(to view: SKView) {
        addBackground()
        physicsWorld.contactDelegate = self
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)

        addBird()
        setupScoreLabel()
        startSpawningPipes()
        
        if let musicURL = Bundle.main.url(forResource: "backgroundMusic", withExtension: "mp3") {
            do {
                backgroundMusicPlayer = try AVAudioPlayer(contentsOf: musicURL)
                backgroundMusicPlayer?.numberOfLoops = -1 // loop forever
                backgroundMusicPlayer?.volume = 0.5
                backgroundMusicPlayer?.play()
            } catch {
                print("❌ Could not load background music: \(error)")
            }
        }
    }

    func addBackground() {
        let background = SKSpriteNode(imageNamed: "background")
        background.position = CGPoint(x: size.width / 2, y: size.height / 2)
        background.zPosition = -1
        background.size = size
        addChild(background)
    }

    func addBird() {
        bird = SKSpriteNode(imageNamed: "bird")
        bird.size = CGSize(width: 55, height: 40)
        bird.position = CGPoint(x: size.width * 0.3, y: size.height / 2)
        bird.physicsBody = SKPhysicsBody(circleOfRadius: 20)
        bird.physicsBody?.affectedByGravity = true
        bird.physicsBody?.allowsRotation = false
        bird.physicsBody?.categoryBitMask = PhysicsCategory.bird
        bird.physicsBody?.contactTestBitMask = PhysicsCategory.pipe | PhysicsCategory.scoreZone
        bird.physicsBody?.collisionBitMask = PhysicsCategory.pipe
        addChild(bird)
    }

    func setupScoreLabel() {
        scoreLabel = SKLabelNode(fontNamed: "Helvetica")
        scoreLabel.fontSize = 30
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 150)
        scoreLabel.text = "0"
        addChild(scoreLabel)
    }

    func startSpawningPipes() {
        let delay = SKAction.wait(forDuration: 1.5)
        let spawn = SKAction.run { self.createPipePair() }
        let sequence = SKAction.sequence([spawn, delay])
        run(SKAction.repeatForever(sequence))
    }

    func createPipePair() {
        let pipeWidth: CGFloat = 200
        let pipeHeight: CGFloat = 500
        let gapHeight: CGFloat = 150
        let xStart = size.width + pipeWidth
        let yOffset = CGFloat.random(in: -80...80)

        let bottomY = size.height / 2 - gapHeight / 2 - pipeHeight / 2 + yOffset
        let topY = size.height / 2 + gapHeight / 2 + pipeHeight / 2 + yOffset

        let pipeBottom = SKSpriteNode(imageNamed: "pipeBottom")
        pipeBottom.size = CGSize(width: pipeWidth, height: pipeHeight)
        pipeBottom.position = CGPoint(x: xStart, y: bottomY)
        pipeBottom.physicsBody = SKPhysicsBody(texture: pipeBottom.texture!, size: pipeBottom.size)
        pipeBottom.physicsBody?.isDynamic = false
        pipeBottom.physicsBody?.categoryBitMask = PhysicsCategory.pipe
        pipeBottom.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        pipeBottom.physicsBody?.collisionBitMask = PhysicsCategory.bird

        let pipeTop = SKSpriteNode(imageNamed: "pipeTop")
        pipeTop.size = CGSize(width: pipeWidth, height: pipeHeight)
        pipeTop.position = CGPoint(x: xStart, y: topY)
        pipeTop.physicsBody = SKPhysicsBody(texture: pipeTop.texture!, size: pipeTop.size)
        pipeTop.physicsBody?.isDynamic = false
        pipeTop.physicsBody?.categoryBitMask = PhysicsCategory.pipe
        pipeTop.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        pipeTop.physicsBody?.collisionBitMask = PhysicsCategory.bird

        let scoreNode = SKNode()
        scoreNode.name = "scoreNode"
        scoreNode.position = CGPoint(x: xStart + pipeWidth / 2, y: size.height / 2 + yOffset)
        scoreNode.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 1, height: gapHeight))
        scoreNode.physicsBody?.isDynamic = false
        scoreNode.physicsBody?.categoryBitMask = PhysicsCategory.scoreZone
        scoreNode.physicsBody?.contactTestBitMask = PhysicsCategory.bird
        scoreNode.physicsBody?.collisionBitMask = 0

        let move = SKAction.moveBy(x: -size.width - pipeWidth * 2, y: 0, duration: 3.5)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([move, remove])

        pipeTop.run(sequence)
        pipeBottom.run(sequence)
        scoreNode.run(sequence)

        addChild(pipeTop)
        addChild(pipeBottom)
        addChild(scoreNode)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if gameOver {
            if let touch = touches.first {
                let location = touch.location(in: self)
                let tappedNode = atPoint(location)
                if tappedNode.name == "restart" {
                    restartGame()
                }
            }
            return
        }

        bird.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
        bird.physicsBody?.applyImpulse(CGVector(dx: 0, dy: 25))
    }

    func didBegin(_ contact: SKPhysicsContact) {
        let contactMask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if contactMask == (PhysicsCategory.bird | PhysicsCategory.scoreZone) {
            let nodeA = contact.bodyA.node
            let nodeB = contact.bodyB.node

            let scoreNode = nodeA?.name == "scoreNode" ? nodeA : nodeB?.name == "scoreNode" ? nodeB : nil

            if let node = scoreNode, node.name == "scoreNode" {
                node.name = "scored"
                score += 1
                scoreLabel.text = " \(score)"
            }
        } else if contactMask == (PhysicsCategory.bird | PhysicsCategory.pipe) {
            triggerGameOver()
        }
    }

    override func update(_ currentTime: TimeInterval) {
        if bird.position.y < 0 && !gameOver {
            triggerGameOver()
        }
    }

    func triggerGameOver() {
        guard !gameOver else { return }
        gameOver = true
        bird.physicsBody?.velocity = .zero
        bird.physicsBody?.isDynamic = false
        removeAllActions()

        gameOverLabel = SKLabelNode(text: "Game Over")
        gameOverLabel.fontName = "Helvetica-Bold"
        gameOverLabel.fontSize = 40
        gameOverLabel.fontColor = .red
        gameOverLabel.position = CGPoint(x: size.width / 2, y: size.height / 2 + 40)
        addChild(gameOverLabel)

        restartButton = SKLabelNode(text: "Tap to Restart")
        restartButton.fontName = "Helvetica"
        restartButton.fontSize = 24
        restartButton.fontColor = .white
        restartButton.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        restartButton.name = "restart"
        addChild(restartButton)
    }

    func restartGame() {
        let newScene = GameScene(size: size)
        newScene.scaleMode = scaleMode
        view?.presentScene(newScene, transition: SKTransition.fade(withDuration: 0.5))
    }
}
