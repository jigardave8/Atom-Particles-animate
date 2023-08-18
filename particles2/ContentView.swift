//
//  ContentView.swift
//  particles2
//
//  Created by Jigar on 18/08/23.
//




import SwiftUI

struct GasAtom: Identifiable {
    var id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var radius: CGFloat = 10
    var color: Color = .white
}

enum AtomState {
    case initial, touch1, touch2, touch3, touch4
}

class GasAtoms: ObservableObject {
    @Published var atoms = [GasAtom]()
    var frameWidth: CGFloat = 0 // Width of the screen
    var frameHeight: CGFloat = 0 // Height of the screen
    var state: AtomState = .initial
    var speedMultiplier: CGFloat = 1.0

    func updateAtoms() {
        for index in atoms.indices {
            var particle = atoms[index]

            // Update particle position
            particle.position.x += particle.velocity.x * speedMultiplier
            particle.position.y += particle.velocity.y * speedMultiplier

            // Bounce off walls and adjust position within bounds
            if particle.position.x < particle.radius || particle.position.x > frameWidth - particle.radius {
                particle.velocity.x *= -1
                particle.position.x = min(max(particle.radius, particle.position.x), frameWidth - particle.radius)
            }

            if particle.position.y < particle.radius || particle.position.y > frameHeight - particle.radius {
                particle.velocity.y *= -1
                particle.position.y = min(max(particle.radius, particle.position.y), frameHeight - particle.radius)
            }

            atoms[index] = particle
        }

        // Handle particle collisions
        for i in 0..<atoms.count {
            for j in i + 1..<atoms.count {
                let distance = atoms[i].position.distance(to: atoms[j].position)
                let combinedRadii = atoms[i].radius + atoms[j].radius

                if distance < combinedRadii {
                    // Calculate collision response using a more accurate method
                    let collisionNormal = CGVector(dx: atoms[j].position.x - atoms[i].position.x, dy: atoms[j].position.y - atoms[i].position.y)
                    let relativeVelocity = CGVector(dx: atoms[j].velocity.x - atoms[i].velocity.x, dy: atoms[j].velocity.y - atoms[i].velocity.y)
                    let dotProduct = collisionNormal.dx * relativeVelocity.dx + collisionNormal.dy * relativeVelocity.dy

                    if dotProduct < 0 {
                        // Swap velocities to simulate collision
                        let tempVelocity = atoms[i].velocity
                        atoms[i].velocity = atoms[j].velocity
                        atoms[j].velocity = tempVelocity
                    }
                }
            }
        }
    }

    func applyUserInteraction(at touchPosition: CGPoint, geometrySize: CGSize) {
        let colorOptions: [Color]

        switch state {
        case .initial:
            colorOptions = [.red, .green, .blue, .yellow]
            speedMultiplier = 2.0
            state = .touch1
        case .touch1:
            colorOptions = [.red, .green, .blue, .yellow]
            speedMultiplier = 3.5
            state = .touch2
        case .touch2:
            colorOptions = [.red, .green, .blue, .yellow]
            speedMultiplier = 2.0
            state = .touch3
        case .touch3:
            colorOptions = [.red, .green, .blue, .yellow]
            speedMultiplier = 4.5
            state = .touch4
        case .touch4:
            colorOptions = [.white]
            speedMultiplier = 2.0
            state = .initial
        }

        for index in atoms.indices {
            let direction = CGPoint(x: touchPosition.x - atoms[index].position.x, y: touchPosition.y - atoms[index].position.y)
            let length = sqrt(direction.x * direction.x + direction.y * direction.y)
            atoms[index].velocity = CGPoint(x: direction.x / length, y: direction.y / length)
            atoms[index].color = colorOptions.randomElement() ?? .white
            atoms[index].velocity.x *= speedMultiplier
            atoms[index].velocity.y *= speedMultiplier
        }
    }
}

struct GasAtomsView: View {
    @ObservedObject var atoms: GasAtoms

    var body: some View {
        ZStack {
            ForEach(atoms.atoms) { atom in
                Circle()
                    .fill(atom.color)
                    .frame(width: atom.radius * 2, height: atom.radius * 2)
                    .position(atom.position)
            }
        }
    }
}

struct ContentView: View {
    @StateObject var atoms = GasAtoms()
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            VStack {
                Button(action: {
                    isAnimating.toggle()
                    if isAnimating {
                        let _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                            atoms.updateAtoms()
                        }
                    }
                }) {
                    Text(isAnimating ? "Stop Animation" : "Start Animation")
                }
                if isAnimating {
                    GasAtomsView(atoms: atoms)
                        .onAppear {
                            atoms.atoms.removeAll() // Clear any previous atoms
                            atoms.frameWidth = geometry.size.width
                            atoms.frameHeight = geometry.size.height
                            for _ in 0..<50 {
                                let randomPosition = CGPoint(x: CGFloat.random(in: 0...atoms.frameWidth), y: CGFloat.random(in: 0...atoms.frameHeight))
                                let randomVelocity = CGPoint(x: CGFloat.random(in: -1...1), y: CGFloat.random(in: -1...1))
                                atoms.atoms.append(GasAtom(position: randomPosition, velocity: randomVelocity))
                            }
                        }
                        .onTapGesture { touchPosition in
                            atoms.applyUserInteraction(at: touchPosition, geometrySize: geometry.size)
                        }
                }
            }
        }
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt((point.x - x) * (point.x - x) + (point.y - y) * (point.y - y))
    }
}





                   
