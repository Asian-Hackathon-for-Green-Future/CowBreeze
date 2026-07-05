import SwiftUI
import MapKit

struct MapDashboardView: View {
    @EnvironmentObject var appState: AppState
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var showConfirm = false
    @State private var didSpray = false
    @State private var showSprayResult = false
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                summaryHeader
                ammoniaStrip
                WeatherStrip(weather: appState.weather)
                
                ZStack(alignment: .top) {
                    mapLayer
                    
                    if showConfirm {
                        SprayConfirmCard(
                            recommended: effectiveRecommendedSpray,
                            onCancel: { showConfirm = false },
                            onConfirm: { confirmSpray() }
                        )
                        .padding(.top, 130)
                    }
                }
                
                VStack(spacing: 0) {
                    sprayButton
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color.cowBackground)
            }
            
            // ── 플로팅 테스트 버튼 (FAB)
            Button {
                appState.simulateAmmoniaSpike()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "flask.fill")
                        .font(.system(size: 18))
                    Text("Test")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(.black)
                .frame(width: 60, height: 60)
                .background(Color.cowYellow)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            }
            .padding(.trailing, 20)
            .padding(.bottom, 110) // 탭바 + 분사버튼 위
            
            // ── 분사 후 절감 토스트
            if showSprayResult {
                sprayResultToast
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 100)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .background(Color.cowBackground)
        .onAppear {
            centerCamera(on: appState.farm.coordinate)
            appState.startWeatherPolling()
        }
        .onChange(of: appState.farm.coordinate.latitude) { _, _ in
            centerCamera(on: appState.farm.coordinate)
        }
        .onChange(of: appState.farm.coordinate.longitude) { _, _ in
            centerCamera(on: appState.farm.coordinate)
        }
        .onDisappear {
            appState.stopWeatherPolling()
        }
        .animation(.spring(response: 0.4), value: showSprayResult)
    }
    
    private func showSprayResultToast() {
        withAnimation { showSprayResult = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showSprayResult = false }
        }
    }
    
    private var sprayResultToast: some View {
        VStack(spacing: 4) {
            Text("You saved ₩7,500")
                .font(.subheadline.bold())
                .foregroundStyle(Color.cowGreen)
            Text("At this rate, ₩900,000 savings this month")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
    }
    
    /// Recenters the map camera on the given coordinate. Called on first
    /// appearance and whenever the registered farm location changes, so the
    /// map doesn't stay stuck on a leftover default location.
    private func centerCamera(on coordinate: CLLocationCoordinate2D) {
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012))
            )
        }
    }
    
    // MARK: - Ammonia Monitoring
    
    private var ammoniaStrip: some View {
        let status = appState.nh3DynamicStatus
        let statusColor: Color = status == .good ? .green : status == .caution ? .orange : Color.cowRed
        
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("NH₃ Level")
                    .font(.caption2).foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Text(String(format: "%.1f ppm", appState.ammonia.concentration))
                        .font(.headline.bold())
                    Text(status.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(statusColor.opacity(0.15))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }
            }
            Spacer()
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
    }
    
    private var currentDecision: SprayRecommendation {
        let windDirection = CompassDirection.nearest(toDegrees: appState.weather.windDegrees)
        return SprayDecisionEngine(
            ammoniaStatus: appState.nh3DynamicStatus,
            populatedDirections: appState.populatedDirections,
            windSpeed: appState.weather.windSpeed,
            windDirection: windDirection
        ).recommendation
    }
    
    private var currentDecisionReason: String? {
        let decision = currentDecision
        guard decision.shouldSpray || appState.ammonia.status != .good else {
            return nil
        }
        return "[\(decision.sprayIntensity.rawValue)] \(decision.reason)"
    }
    
    // MARK: - Header
    
    private var todayLabel: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d"
        return f.string(from: Date())
    }
    
    private var summaryHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.65))
                        .tracking(1.5)
                    Text(todayLabel)
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                }
                Spacer()
                // 오늘 절감 비용 — 날짜 옆
                if appState.todayStats.savedWon > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Saved Today")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(compactWon(appState.todayStats.savedWon))
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.cowYellow)
                    }
                } else {
                    Image(systemName: "cowboy.hat.fill")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            HStack(spacing: 0) {
                statColumn(value: "\(appState.todayStats.sprayCount)", label: "Sprays")
                Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 36)
                statColumn(value: "\(appState.todayStats.sprayCount * 60)ml", label: "Volume")
                Rectangle().fill(.white.opacity(0.2)).frame(width: 1, height: 36)
                statColumn(value: compactWon(appState.todayStats.spendWon), label: "Cost")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [Color.cowGreenDark, Color.cowGreen],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    private func compactWon(_ amount: Int) -> String {
        if amount == 0 { return "₩0" }
        if amount >= 1_000_000 { return String(format: "₩%.1fM", Double(amount) / 1_000_000) }
        if amount >= 100_000 { return String(format: "₩%.0fK", Double(amount) / 1_000) }
        if amount >= 1_000 {
            return String(format: "₩%.1fK", Double(amount) / 1_000)
        } else {
            return String(format: "₩%.1fK", Double(amount) / 1_000)
        }
    }
    
    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Map
    
    private var mapLayer: some View {
        Map(position: $cameraPosition) {
            Annotation(appState.farm.name, coordinate: appState.farm.coordinate) {
                FarmPinView()
            }
            
            // 바람이 도심 방향일 때만 빨간 부채꼴 표시
            if isRiskyWind {
                MapPolygon(coordinates: wedgeCoordinates(for: windTargetDirection))
                    .foregroundStyle(Color.cowRed.opacity(0.28))
                    .stroke(Color.cowRed, lineWidth: 1.5)
            }
        }
        .mapStyle(.standard)
        .overlay(alignment: .topLeading) {
            compass.padding(16)
        }
        .overlay(alignment: .topTrailing) {
            riskLabel.padding(16)
        }
    }
    
    /// 해당 방향으로 퍼지는 부채꼴 폴리곤 좌표 생성
    private func wedgeCoordinates(for direction: CompassDirection) -> [CLLocationCoordinate2D] {
        let origin = appState.farm.coordinate
        let bearing = direction.bearingDegrees
        return [
            origin,
            origin.offset(bearingDegrees: bearing - 18, distanceMeters: 1200),
            origin.offset(bearingDegrees: bearing - 9,  distanceMeters: 1600),
            origin.offset(bearingDegrees: bearing,      distanceMeters: 1800),
            origin.offset(bearingDegrees: bearing + 9,  distanceMeters: 1600),
            origin.offset(bearingDegrees: bearing + 18, distanceMeters: 1200)
        ]
    }
    
    private var compass: some View {
        VStack(spacing: 2) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 44, height: 44)
                // 나침반 눈금
                ForEach([0, 90, 180, 270], id: \.self) { deg in
                    Rectangle()
                        .fill(Color.primary.opacity(0.2))
                        .frame(width: 1, height: 6)
                        .offset(y: -16)
                        .rotationEffect(.degrees(Double(deg)))
                }
                // 북쪽 N 마크
                Text("N")
                    .font(.system(size: 7, weight: .black))
                    .foregroundStyle(Color.cowRed)
                    .offset(y: -13)
                // 바람 방향 화살표
                Image(systemName: "arrowtriangle.up.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.cowGreen)
                    .rotationEffect(.degrees(appState.weather.windDegrees))
            }
            Text(appState.weather.windDirection)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.primary)
        }
        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
    }
    
    private var riskLabel: some View {
        Label(riskBadgeText, systemImage: riskBadgeIcon)
            .font(.caption2.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(riskBadgeColor)
            .foregroundStyle(.white)
            .clipShape(Capsule())
            .shadow(radius: 2)
    }
    
    private var riskBadgeText: String {
        if appState.isAnalyzingDirections { return "Analyzing area..." }
        else if isRiskyWind { return "Odor risk toward \(windTargetDirection.rawValue)" }
        else { return "No spread risk" }
    }
    
    private var riskBadgeIcon: String {
        if appState.isAnalyzingDirections { return "hourglass" }
        else if isRiskyWind { return "exclamationmark.triangle.fill" }
        else { return "checkmark.circle.fill" }
    }
    
    private var riskBadgeColor: Color {
        if appState.isAnalyzingDirections { return .gray }
        else if isRiskyWind { return Color.cowRed }
        else { return Color.cowGreen }
    }
    
    /// Nearest cardinal bucket for today's wind direction.
    private var windTargetDirection: CompassDirection {
        CompassDirection.nearest(toDegrees: appState.weather.windDegrees)
    }
    
    /// True when the wind is blowing toward a direction we've detected as
    /// populated — i.e. odor is likely to reach people today.
    private var isRiskyWind: Bool {
        appState.populatedDirections.contains(windTargetDirection)
    }
    
    private var effectiveRecommendedSpray: RecommendedSpray {
        RecommendedSpray(
            volumeLiters: appState.recommendedSpray.volumeLiters,
            location: isRiskyWind ? windTargetDirection.rawValue : appState.recommendedSpray.location
        )
    }
    
    // MARK: - Bottom button
    
    private var sprayButton: some View {
        Button {
            showConfirm = true
        } label: {
            Label(didSpray ? "Spray Done ✓" : "Start Spray", systemImage: "drop.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .foregroundStyle(.white)
                .background(didSpray ? Color.cowGreen.opacity(0.5) : Color.cowGreen)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .animation(.easeInOut(duration: 0.3), value: didSpray)
        }
        .disabled(didSpray)
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(Color.cowBackground)
    }
    
    private func confirmSpray() {
        showConfirm = false
        didSpray = true
        appState.recordSpray(volumeLiters: effectiveRecommendedSpray.volumeLiters)
        showSprayResultToast()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            withAnimation { didSpray = false }
        }
    }
}
