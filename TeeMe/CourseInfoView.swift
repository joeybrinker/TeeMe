import SwiftUI
import MapKit
import FirebaseAuth

struct CourseInfoView: View {
    // MARK: - Properties
    
    // Add this line to use the shared model
    @EnvironmentObject var courseModel: CourseDataModel
    
    // Input properties passed from parent view
    var selectedMapItem: MKMapItem?
    var route: MKRoute?
    
    // Favorite state
    @State private var isFavorited: Bool = false
    
    // Weather
    @StateObject private var weatherManager = WeatherKitManager()
    
    // Weather forecast sheet
    @State private var showingWeatherForecast: Bool = false
    
    // MARK: - Computed Properties
    
    // Formatted travel time for the route
    private var travelTime: String? {
        guard let route else { return nil }
        
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.hour, .minute]
        return formatter.string(from: route.expectedTravelTime)
    }
    
    // MARK: - View Body
    var body: some View {
        // Main content view
        overlayContent
            .onAppear {
                // Set initial favorite state when view appears
                if let course = selectedMapItem {
                    isFavorited = courseModel.isFavorite(courseName: course.placemark.name ?? "")
                    weatherManager.fetchWeather(for: CLLocation(
                        latitude: selectedMapItem?.placemark.coordinate.latitude ?? 0,
                        longitude: selectedMapItem?.placemark.coordinate.longitude ?? 0
                    ))
                }
            }
            .onChange(of: selectedMapItem) { _, newValue in
                // Update weather when course changes
                if let course = newValue {
                    isFavorited = courseModel.isFavorite(courseName: course.placemark.name ?? "")
                    weatherManager.fetchWeather(for: CLLocation(
                        latitude: course.placemark.coordinate.latitude,
                        longitude: course.placemark.coordinate.longitude
                    ))
                }
            }
            .sheet(isPresented: $showingWeatherForecast) {
                WeatherForecastView(weatherManager: weatherManager)
            }
    }
    
    // MARK: - UI Components
    
    // Information overlay showing name and travel time
    private var overlayContent: some View {
        VStack(alignment: .center, spacing: 15) {
            // Location name
            if let name = selectedMapItem?.name {
                Text(name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding()
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            
            HStack {
                // Travel time if available
                if let time = travelTime {
                    Text("Travel time: \(time)")
                        .font(.subheadline)
                }
                else {
                    Text("Travel time: --")
                        .font(.subheadline)
                }
                
                Spacer()
                
                // Tappable weather display with colorful symbol
                Button {
                    showingWeatherForecast = true
                } label: {
                    HStack(spacing: 4) {
                        WeatherSymbolView(symbolName: weatherManager.symbolName)
                            .frame(width: 20, height: 20)
                        
                        Text(weatherManager.temperature)
                            .foregroundColor(.primary)
                            .font(.subheadline)
                    }
                    .padding(5)
                    .background(.ultraThickMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal)
            
            // Favorite button - updated to use the course model
            HStack{
                Text(isFavorited ? "Remove from favorites" : "Add to favorites")
                    .font(.subheadline)
                
                Spacer()
                
                Button {
                    if Auth.auth().currentUser != nil{
                        if let selectedCourse = selectedMapItem {
                            isFavorited = courseModel.toggleFavorite(for: selectedCourse)
                            courseModel.showSignIn = false
                            print(selectedCourse.id)
                        }
                    }
                    else {
                        courseModel.showSignIn = true
                    }
                } label: {
                    Image(systemName: courseModel.isFavorite(courseName: selectedMapItem?.placemark.name ?? "") ? "star.fill" : "star")
                        .foregroundStyle(.green)
                }
                .font(.title3)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
    }
}

#Preview {
    CourseInfoView()
        .environmentObject(CourseDataModel())
}
