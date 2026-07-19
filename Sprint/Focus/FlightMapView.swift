import SwiftUI
import MapKit

/// The FocusFlight "running" screen: a live map tracking a plane moving in a straight
/// line from departure to arrival. Fully interactive — the user can pan/zoom/rotate
/// freely; the camera only moves on its own once, framing the whole route on appear, plus
/// whenever "recenter" is tapped, rather than fighting a manual pan every second.
struct FlightMapView: View {
    let departure: Destination
    let arrival: Destination
    /// 0 at takeoff, 1 at landing. Ticks once per second from the engine — `animatedProgress`
    /// is what actually drives the plane, so it glides continuously between those ticks
    /// instead of hopping in one-second jumps.
    let progress: Double
    let secondsLeft: Int
    let distanceRemainingKm: Int

    @State private var animatedProgress: Double = 0
    @State private var cameraPosition: MapCameraPosition = .automatic

    private func coordinate(at fraction: Double) -> CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: departure.coordinate.latitude + (arrival.coordinate.latitude - departure.coordinate.latitude) * fraction,
            longitude: departure.coordinate.longitude + (arrival.coordinate.longitude - departure.coordinate.longitude) * fraction
        )
    }

    private var planeCoordinate: CLLocationCoordinate2D {
        coordinate(at: animatedProgress)
    }

    /// Bearing from departure to arrival, so the plane icon faces the direction of travel.
    private var bearingDegrees: Double {
        let lat1 = departure.coordinate.latitude * .pi / 180
        let lat2 = arrival.coordinate.latitude * .pi / 180
        let deltaLon = (arrival.coordinate.longitude - departure.coordinate.longitude) * .pi / 180
        let y = sin(deltaLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)
        return (atan2(y, x) * 180 / .pi).truncatingRemainder(dividingBy: 360)
    }

    var body: some View {
        ZStack {
            Map(position: $cameraPosition) {
                MapPolyline(coordinates: [departure.coordinate, arrival.coordinate])
                    .stroke(Color.theme.orange, style: StrokeStyle(lineWidth: 3, dash: [1, 8]))

                Annotation("", coordinate: planeCoordinate) {
                    planeIcon
                }
            }
            .onAppear {
                animatedProgress = progress
                cameraPosition = .region(boundingRegion())
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.linear(duration: 1)) {
                    animatedProgress = newValue
                }
            }

            VStack {
                HStack {
                    Spacer()
                    recenterButton
                }
                .padding(.top, 16)
                .padding(.trailing, 16)

                Spacer()

                HStack(alignment: .bottom) {
                    stat(title: "TIME REMAINING", value: timeLabel, alignment: .leading)
                    Spacer()
                    stat(title: "DISTANCE REMAINING", value: "\(distanceRemainingKm) km", alignment: .trailing)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 32)
                .allowsHitTesting(false)
            }
        }
    }

    /// Not a real 3D model — this tool can't generate one. A `rotation3DEffect` tilt plus
    /// a radial highlight on a flat SF Symbol, to read as more dimensional than a plain
    /// flat icon.
    private var planeIcon: some View {
        Image(systemName: "airplane")
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(
                LinearGradient(colors: [Color.theme.espresso, Color.theme.espresso.opacity(0.65)], startPoint: .top, endPoint: .bottom)
            )
            .rotationEffect(.degrees(bearingDegrees - 90))
            .rotation3DEffect(.degrees(22), axis: (x: 1, y: 0.3, z: 0), perspective: 0.6)
            .padding(9)
            .background(
                Circle().fill(
                    RadialGradient(colors: [Color.white, Color.white.opacity(0.82)], center: .topLeading, startRadius: 1, endRadius: 26)
                )
            )
            .shadow(color: Color.theme.espresso.opacity(0.45), radius: 6, y: 3)
    }

    private var recenterButton: some View {
        Button {
            withAnimation { cameraPosition = .region(boundingRegion()) }
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.theme.espresso)
                .frame(width: 36, height: 36)
                .background(Circle().fill(Color.white))
                .shadow(color: Color.theme.espresso.opacity(0.3), radius: 4, y: 2)
        }
    }

    private var timeLabel: String {
        let minutes = secondsLeft / 60
        let seconds = secondsLeft % 60
        return minutes > 0 ? "\(minutes) min" : "\(seconds) sec"
    }

    private func stat(title: String, value: String, alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(title)
                .font(.theme.bodySmall())
                .foregroundStyle(Color.white.opacity(0.7))
            Text(value)
                .font(.theme.timerDigits(26))
                .monospacedDigit()
                .foregroundStyle(Color.white)
        }
    }

    /// Frames both cities with padding — computed once on appear (and on "recenter"), not
    /// forced every tick, so it never fights a manual pan.
    private func boundingRegion() -> MKCoordinateRegion {
        let lats = [departure.coordinate.latitude, arrival.coordinate.latitude]
        let lons = [departure.coordinate.longitude, arrival.coordinate.longitude]
        let minLat = lats.min() ?? 0, maxLat = lats.max() ?? 0
        let minLon = lons.min() ?? 0, maxLon = lons.max() ?? 0

        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.6, 1.0),
            longitudeDelta: max((maxLon - minLon) * 1.6, 1.0)
        )
        return MKCoordinateRegion(center: center, span: span)
    }
}
