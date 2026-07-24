import SwiftUI
import MapKit
struct LocationThumbnailView: View {
    let locationName: String
    let latitude: Double
    let longitude: Double

    var region: MKCoordinateRegion {
        MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Map(initialPosition: .region(region)) {
                Marker(locationName, coordinate: .init(latitude: latitude, longitude: longitude))
            }
            .frame(height: 120)
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.secondary)
                Text(locationName)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(8)
            .background(Color.secondarySystemGroupedBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}
#Preview {
    LocationThumbnailView(locationName: "Central Park", latitude: 40.785091, longitude: -73.968285)
}
