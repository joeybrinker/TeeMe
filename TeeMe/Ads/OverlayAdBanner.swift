import SwiftUI
import GoogleMobileAds

// MARK: - 1. OVERLAY ADS (for Map, Favorites, Profile)

struct OverlayAdBanner: View {
    let adUnitID: String
    @State private var bannerHeight: CGFloat = 50
    
    var body: some View {
        VStack {
            HStack {
                // Ad content takes full width
                GeometryReader { geometry in
                    let adSize = currentOrientationAnchoredAdaptiveBanner(width: geometry.size.width * 0.95)
                    
                    SimpleBannerView(adUnitID: adUnitID, adSize: adSize)
                        .frame(width: adSize.size.width, height: adSize.size.height)
                        .onAppear {
                            bannerHeight = adSize.size.height
                        }
                }
                .frame(height: bannerHeight)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 3)
        }
    }
}

struct SimpleBannerView: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize
    
    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        bannerView.rootViewController = getRootViewController()
        bannerView.load(Request())
        return bannerView
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("Banner ad loaded")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("Banner ad failed: \(error.localizedDescription)")
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

// MARK: - 2. NATIVE ADS (for Feed View)

struct NativeAdPostView: View {
    @StateObject private var nativeAdViewModel = NativeAdViewModel()
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.gray.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(.yellow, lineWidth: 1)
                )
            
            if nativeAdViewModel.isAdLoaded {
                VStack(spacing: 0) {
                    // Ad header with "Sponsored" label
                    adHeader
                    
                    Spacer()
                    
                    // Ad content area
                    adContent
                    
                    Spacer()
                    
                    // Static footer (no button)
                    adFooter
                }
            } else {
                // Placeholder while ad loads
                VStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                    Text("Loading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 325, height: 200)
        .onAppear {
            nativeAdViewModel.loadAd()
        }
    }
    
    private var adHeader: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("Sponsored")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.yellow.opacity(0.1))
            .cornerRadius(4)
            
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var adContent: some View {
        VStack(spacing: 8) {
            if let nativeAd = nativeAdViewModel.nativeAd {
                Text(nativeAd.headline ?? "Golf Equipment & Accessories")
                    .font(.title3.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                Text(nativeAd.body ?? "Discover premium golf gear to improve your game")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.center)
            } else {
                Text("Golf Equipment & Accessories")
                    .font(.title3.weight(.semibold))
                
                Text("Discover premium golf gear")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }
    
    private var adFooter: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .foregroundStyle(.yellow)
                    .font(.caption)
                Text("Promoted")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Static text instead of button
            Text("Ad")
                .font(.caption.weight(.medium))
                .foregroundStyle(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(.green.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
}

class NativeAdViewModel: NSObject, ObservableObject {
    @Published var isAdLoaded = false
    @Published var nativeAd: NativeAd?
    
    private var adLoader: AdLoader?
    
    func loadAd() {
        guard adLoader == nil else { return }
        
        let adUnitID = "ca-app-pub-3940256099942544/2247696110"
        
        adLoader = AdLoader(
            adUnitID: adUnitID,
            rootViewController: getRootViewController(),
            adTypes: [.native],
            options: nil
        )
        
        adLoader?.delegate = self
        adLoader?.load(Request())
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
}

extension NativeAdViewModel: AdLoaderDelegate, NativeAdLoaderDelegate {
    func adLoader(_ adLoader: AdLoader, didReceive nativeAd: NativeAd) {
        DispatchQueue.main.async {
            self.nativeAd = nativeAd
            self.isAdLoaded = true
        }
    }
    
    func adLoader(_ adLoader: AdLoader, didFailToReceiveAdWithError error: Error) {
        print("Native ad failed to load: \(error.localizedDescription)")
        
        DispatchQueue.main.async {
            self.isAdLoaded = false
        }
    }
}

// MARK: - 3. VIEW EXTENSIONS

extension View {
    func overlayAd(adUnitID: String, position: OverlayPosition = .bottom) -> some View {
        ZStack {
            self
            
            VStack {
                if position == .top {
                    OverlayAdBanner(adUnitID: adUnitID)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    Spacer()
                } else {
                    Spacer()
                    OverlayAdBanner(adUnitID: adUnitID)
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                }
            }
        }
    }
}

enum OverlayPosition {
    case top
    case bottom
}
