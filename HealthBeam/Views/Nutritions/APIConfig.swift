import Foundation

public enum APIConfig {
    public static let edamamAppId = "96b6c2e9"
    public static let edamamAppKey = "b9673e5c43ba0044fb5aeea00107d6ff"
    
    public static var isConfigured: Bool {
        return !edamamAppId.isEmpty && edamamAppId != "YOUR_EDAMAM_APP_ID" && 
               !edamamAppKey.isEmpty && edamamAppKey != "YOUR_EDAMAM_APP_KEY"
    }
}
