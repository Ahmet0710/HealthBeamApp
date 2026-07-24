import MapKit
import Combine
extension MKCoordinateRegion {
    static var defaultRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 39.9334, longitude: 32.8597), // Ankara koordinatları
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    }
}
