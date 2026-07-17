import SwiftUI
import MapKit

/// The FocusFlight "running" screen: a live map tracking a plane moving in a straight
/// line from departure to arrival, with the same camera-follows-plane feel as a real
/// airline flight tracker. Non-interactive by design — nothing here should invite the
/// user to touch and pan around during a session meant to keep them off their phone.
struct FlightMapView: View {
    let departure: Destination
    let arrival: Destination
    /// 0 at takeoff, 1 at landing.
    let progress: Double
    let secondsLeft: Int
    let distanceRemainingKm: Int

    @State private var cameraPosition: MapCameraPosition = .automatic

    private var planeCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: departure.coordinate.latitude + (arrival.coordinate.latitude - departure.coordinate.latitude) * progress,
            longitude: departure.coordinate.longitude + (arrival.coordinate.longitude - departure.coordinate.longitude) * progress
        )
    }

    /// Initial bearing from departure to arrival, so the plane icon faces the direction
    /// of travel rather than sitting at a fixed rotation for the whole flight.
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
                    .stroke(Color.theme.taupe, style: StrokeStyle(lineWidth: 3, dash: [1, 8]))

                Annotation("", coordinate: planeCoordinate) {
                    Image(systemName: "airplane")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.theme.leather)
                        // The SF Symbol's default heading hasn't been confirmed on-device;
                        // nudge this offset if the icon doesn't line up with the route.
                        .rotationEffect(.degrees(bearingDegrees - 90))
                        .padding(9)
                        .background(Circle().fill(Color.theme.white))
                        .shadow(color: Color.theme.leather.opacity(0.4), radius: 5)
                }
            }
            .allowsHitTesting(false)
            .onAppear { recenter(animated: false) }
            .onChange(of: progress) { _, _ in recenter(animated: true) }

            VStack {
                Spacer()
                HStack(alignment: .bottom) {
                    stat(title: "TIME REMAINING", value: timeLabel, alignment: .leading)
                    Spacer()
                    stat(title: "DISTANCE REMAINING", value: "\(distanceRemainingKm) km", alignment: .trailing)
                }
                .padding(.horizontal, 36)
                .padding(.bottom, 32)
            }
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
                .font(.theme.caption(11))
                .foregroundStyle(Color.theme.white.opacity(0.7))
            Text(value)
                .font(.theme.display(26))
                .monospacedDigit()
                .foregroundStyle(Color.theme.white)
        }
    }

    private func recenter(animated: Bool) {
        let region = MKCoordinateRegion(center: planeCoordinate, span: MKCoordinateSpan(latitudeDelta: 6, longitudeDelta: 6))
        if animated {
            withAnimation(.linear(duration: 1)) {
                cameraPosition = .region(region)
            }
        } else {
            cameraPosition = .region(region)
        }
    }
}
