import Foundation
import Observation

enum Team: String, Codable {
    case us = "Us"
    case them = "Them"
}

struct PointEntry: Identifiable {
    let id = UUID()
    let team: Team
    let description: String
    let timestamp: Date
}

struct SetScore: Equatable {
    var games: [Int] = [0, 0] // [us, them]
    var tiebreakPoints: [Int]? // only during tiebreak
}

@Observable
final class MatchEngine {
    // Score state
    var points: [Int] = [0, 0]          // 0,1,2,3 = 0,15,30,40
    var games: [[Int]] = [[0, 0]]       // games per set
    var setResults: [(Int, Int)] = []    // completed sets
    var currentSet: Int = 0
    var isTiebreak = false
    var tiebreakPoints: [Int] = [0, 0]
    var isDeuce = false
    var advantage: Team? = nil
    var matchWinner: Team? = nil
    var setsWon: [Int] = [0, 0]

    // History
    var history: [PointEntry] = []
    private var snapshots: [Snapshot] = []

    private struct Snapshot {
        let points: [Int]
        let games: [[Int]]
        let setResults: [(Int, Int)]
        let currentSet: Int
        let isTiebreak: Bool
        let tiebreakPoints: [Int]
        let isDeuce: Bool
        let advantage: Team?
        let matchWinner: Team?
        let setsWon: [Int]
    }

    static let pointLabels = ["0", "15", "30", "40"]

    var pointDisplay: (String, String) {
        if matchWinner != nil { return ("—", "—") }
        if isTiebreak {
            return ("\(tiebreakPoints[0])", "\(tiebreakPoints[1])")
        }
        if isDeuce {
            if let adv = advantage {
                return adv == .us ? ("AD", "—") : ("—", "AD")
            }
            return ("40", "40")
        }
        return (Self.pointLabels[points[0]], Self.pointLabels[points[1]])
    }

    var currentGames: (Int, Int) {
        let g = games[currentSet]
        return (g[0], g[1])
    }

    func scorePoint(for team: Team) {
        guard matchWinner == nil else { return }
        saveSnapshot()

        let idx = team == .us ? 0 : 1
        let other = 1 - idx

        if isTiebreak {
            scoreTiebreakPoint(winner: idx, loser: other, team: team)
        } else if isDeuce {
            scoreDeucePoint(winner: idx, team: team)
        } else {
            scoreRegularPoint(winner: idx, loser: other, team: team)
        }
    }

    private func scoreRegularPoint(winner: Int, loser: Int, team: Team) {
        if points[winner] == 3 {
            if points[loser] == 3 {
                // Enter deuce
                isDeuce = true
                advantage = team
                addHistory(team: team, desc: "\(team.rawValue) point → Advantage")
            } else {
                // Win game
                addHistory(team: team, desc: "\(team.rawValue) wins game")
                winGame(winner: winner)
            }
        } else {
            points[winner] += 1
            addHistory(team: team, desc: "\(team.rawValue) point → \(pointDisplay.0)-\(pointDisplay.1)")
        }
    }

    private func scoreDeucePoint(winner: Int, team: Team) {
        if let adv = advantage {
            if (adv == .us && winner == 0) || (adv == .them && winner == 1) {
                addHistory(team: team, desc: "\(team.rawValue) wins game (from AD)")
                winGame(winner: winner)
            } else {
                advantage = nil
                addHistory(team: team, desc: "\(team.rawValue) point → Deuce")
            }
        } else {
            advantage = team
            addHistory(team: team, desc: "\(team.rawValue) point → Advantage")
        }
    }

    private func scoreTiebreakPoint(winner: Int, loser: Int, team: Team) {
        tiebreakPoints[winner] += 1
        let w = tiebreakPoints[winner]
        let l = tiebreakPoints[loser]

        if w >= 7 && (w - l) >= 2 {
            addHistory(team: team, desc: "\(team.rawValue) wins tiebreak \(w)-\(l)")
            winGame(winner: winner)
        } else {
            addHistory(team: team, desc: "\(team.rawValue) TB point → \(tiebreakPoints[0])-\(tiebreakPoints[1])")
        }
    }

    private func winGame(winner: Int) {
        games[currentSet][winner] += 1
        resetPoint()

        let g = games[currentSet]

        // Check for set win
        if isTiebreak {
            // Tiebreak game won
            isTiebreak = false
            tiebreakPoints = [0, 0]
            winSet(winner: winner)
        } else if g[winner] >= 6 && (g[winner] - g[1 - winner]) >= 2 {
            winSet(winner: winner)
        } else if g[0] == 6 && g[1] == 6 {
            isTiebreak = true
            tiebreakPoints = [0, 0]
        }
    }

    private func winSet(winner: Int) {
        let g = games[currentSet]
        setResults.append((g[0], g[1]))
        setsWon[winner] += 1

        if setsWon[winner] == 2 {
            matchWinner = winner == 0 ? .us : .them
        } else {
            currentSet += 1
            games.append([0, 0])
        }
    }

    private func resetPoint() {
        points = [0, 0]
        isDeuce = false
        advantage = nil
    }

    private func addHistory(team: Team, desc: String) {
        history.insert(PointEntry(team: team, description: desc, timestamp: .now), at: 0)
    }

    private func saveSnapshot() {
        snapshots.append(Snapshot(
            points: points, games: games, setResults: setResults,
            currentSet: currentSet, isTiebreak: isTiebreak,
            tiebreakPoints: tiebreakPoints, isDeuce: isDeuce,
            advantage: advantage, matchWinner: matchWinner, setsWon: setsWon
        ))
    }

    var canUndo: Bool { !snapshots.isEmpty }

    func undo() {
        guard let snap = snapshots.popLast() else { return }
        points = snap.points; games = snap.games; setResults = snap.setResults
        currentSet = snap.currentSet; isTiebreak = snap.isTiebreak
        tiebreakPoints = snap.tiebreakPoints; isDeuce = snap.isDeuce
        advantage = snap.advantage; matchWinner = snap.matchWinner
        setsWon = snap.setsWon
        if !history.isEmpty { history.removeFirst() }
    }

    func newMatch() {
        points = [0, 0]; games = [[0, 0]]; setResults = []
        currentSet = 0; isTiebreak = false; tiebreakPoints = [0, 0]
        isDeuce = false; advantage = nil; matchWinner = nil
        setsWon = [0, 0]; history = []; snapshots = []
    }
}
