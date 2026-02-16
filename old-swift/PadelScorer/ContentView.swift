import SwiftUI

struct ContentView: View {
    @State private var engine = MatchEngine()
    @State private var speech = SpeechManager()
    @State private var showHistory = false
    @State private var showNewMatchConfirm = false

    let padelBlue = Color(red: 0, green: 0.467, blue: 0.714)

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // Match winner banner
                if let winner = engine.matchWinner {
                    Text("\(winner.rawValue) win the match! 🏆")
                        .font(.title2.bold())
                        .foregroundStyle(padelBlue)
                        .padding(.top, 8)
                }

                // Sets display
                setsView
                    .padding(.top, 12)

                // Current games
                gamesView
                    .padding(.top, 8)

                // Current point
                pointView
                    .padding(.top, 4)

                Spacer()

                // Score buttons
                if engine.matchWinner == nil {
                    scoreButtons
                        .padding(.bottom, 8)
                }

                // Bottom bar
                bottomBar
                    .padding(.bottom, 8)
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $showHistory) {
            historySheet
        }
        .confirmationDialog("New Match?", isPresented: $showNewMatchConfirm) {
            Button("Start New Match", role: .destructive) {
                engine.newMatch()
                speech.stopListening()
            }
            Button("Cancel", role: .cancel) {}
        }
        .onAppear {
            speech.requestPermission()
            speech.onTeamDetected = { team in
                engine.scorePoint(for: team)
            }
        }
    }

    // MARK: - Sets
    private var setsView: some View {
        HStack(spacing: 20) {
            Text("SETS")
                .font(.caption)
                .foregroundStyle(.gray)

            HStack(spacing: 12) {
                ForEach(Array(engine.setResults.enumerated()), id: \.offset) { _, result in
                    HStack(spacing: 4) {
                        Text("\(result.0)").foregroundStyle(result.0 > result.1 ? padelBlue : .gray)
                        Text("-").foregroundStyle(.gray)
                        Text("\(result.1)").foregroundStyle(result.1 > result.0 ? .red : .gray)
                    }
                    .font(.title3.monospacedDigit().bold())
                }
            }

            Spacer()

            // Sets won
            HStack(spacing: 16) {
                Label("\(engine.setsWon[0])", systemImage: "circle.fill")
                    .foregroundStyle(padelBlue)
                Label("\(engine.setsWon[1])", systemImage: "circle.fill")
                    .foregroundStyle(.red)
            }
            .font(.caption.bold())
        }
    }

    // MARK: - Games
    private var gamesView: some View {
        HStack {
            VStack(spacing: 2) {
                Text("Us")
                    .font(.subheadline)
                    .foregroundStyle(padelBlue)
                Text("\(engine.currentGames.0)")
                    .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 4) {
                Text("GAMES")
                    .font(.caption2)
                    .foregroundStyle(.gray)
                if engine.isTiebreak {
                    Text("TB")
                        .font(.caption.bold())
                        .foregroundStyle(.yellow)
                }
            }

            VStack(spacing: 2) {
                Text("Them")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                Text("\(engine.currentGames.1)")
                    .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Point
    private var pointView: some View {
        let display = engine.pointDisplay
        return HStack {
            Text(display.0)
                .foregroundStyle(padelBlue)
                .frame(maxWidth: .infinity)
            Text("·")
                .foregroundStyle(.gray)
            Text(display.1)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity)
        }
        .font(.system(size: 48, weight: .semibold, design: .rounded).monospacedDigit())
    }

    // MARK: - Score buttons
    private var scoreButtons: some View {
        HStack(spacing: 16) {
            Button {
                engine.scorePoint(for: .us)
            } label: {
                Text("Us")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(padelBlue, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }

            Button {
                engine.scorePoint(for: .them)
            } label: {
                Text("Them")
                    .font(.title.bold())
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Bottom bar
    private var bottomBar: some View {
        HStack(spacing: 20) {
            // Undo
            Button {
                engine.undo()
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.title)
                    .foregroundStyle(engine.canUndo ? .white : .gray.opacity(0.3))
            }
            .disabled(!engine.canUndo)

            Spacer()

            // Mic
            Button {
                speech.toggleListening()
            } label: {
                Image(systemName: speech.isListening ? "mic.fill" : "mic.slash.fill")
                    .font(.title)
                    .foregroundStyle(speech.isListening ? .green : .gray)
                    .symbolEffect(.pulse, isActive: speech.isListening)
            }

            Spacer()

            // History
            Button {
                showHistory = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.title)
                    .foregroundStyle(.white)
            }

            Spacer()

            // New match
            Button {
                showNewMatchConfirm = true
            } label: {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.title)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - History sheet
    private var historySheet: some View {
        NavigationStack {
            List(engine.history) { entry in
                HStack {
                    Circle()
                        .fill(entry.team == .us ? padelBlue : .red)
                        .frame(width: 8, height: 8)
                    Text(entry.description)
                        .font(.subheadline)
                    Spacer()
                    Text(entry.timestamp, format: .dateTime.hour().minute().second())
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
            }
            .navigationTitle("Point History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showHistory = false }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    ContentView()
}
