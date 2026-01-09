////
////  ContentView.swift
////  HealthObserver
////
////  Created by KBS on 12/31/25.
////

import SwiftUI
import SwiftData
import HealthKit
import HealthKitUI
import Charts


struct ContentView: View {
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.shadowColor = UIColor.systemGray4
        appearance.largeTitleTextAttributes = [.font: UIFont.systemFont(ofSize: 34, weight: .bold)]
        appearance.titleTextAttributes = [.font: UIFont.systemFont(ofSize: 17, weight: .semibold)]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().prefersLargeTitles = false
    }
    
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = HealthDataViewModel()
    
    @State private var metrics: [HealthMetric] = []
    @State private var draggingItem: HealthMetric?
    @State private var dragOffset: CGSize = .zero

    @State private var dragLocation: CGPoint = .zero


    var body: some View {
        NavigationStack {
            List {
                Section {
                 //   EmptyView()
                } header: {
                    GreetingHeaderView(userName: "KBS")
                        .listRowInsets(EdgeInsets(top: 0, leading: 5, bottom: 8, trailing: 5))
                        .listRowBackground(Color.clear)
                }
                VStack {
                    LazyVStack(spacing: 15) {
                        ForEach(metrics) { metric in
                            HealthCard(
                                title: metric.title,
                                value: metric.value,
                                unit: metric.unit,
                                activity: metric.activity,
                                icon: metric.icon,
                                graphData: metric.graphData
                            )
                            .opacity(draggingItem?.id == metric.id ? 0 : 1)   // hide original
                        }
                    }
                    // Floating dragged card
                    if let draggingItem {
                        HealthCard(
                            title: draggingItem.title,
                            value: draggingItem.value,
                            unit: draggingItem.unit,
                            activity: draggingItem.activity,
                            icon: draggingItem.icon,
                            graphData: draggingItem.graphData
                        )
                        .scaleEffect(1.05)
                        .shadow(radius: 14)
                        .position(dragLocation)
                        .animation(.spring(), value: dragLocation)
                        .allowsHitTesting(false)
                    }
                }

                .listRowInsets(EdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain) // 🔥 removes default padding
            .background(Color.healthBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Image("ic_account")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                }
                ToolbarItem(placement: .principal) { Text("Your Health Data") .font(.system(size: 20, weight: .bold)) .foregroundColor(.black) }
            }
        }
        .onAppear {
            Task {
                await viewModel.requestAuthorization(complition: {result in
                    if result{
                        UpdateData()
                    }
                    
                })
              
            }
            
        }
    }
    
    func UpdateData(){
        metrics = [
       
            HealthMetric(title: "Steps", value: "\(Int(viewModel.stepCount))", unit: "steps",activity:"steps", icon: .steps, graphData: viewModel.stepsGraph),

            HealthMetric(title: "Heart Rate", value: "\(String(format: "%.1f bpm", viewModel.heartRate))", unit: "bpm",activity:"Heart Rate", icon: .heartRate, graphData: viewModel.heartRateGraph),

            HealthMetric(title: "Active Energy", value: "\(String(format: "%.1f kcal", viewModel.activeEnergy))", unit: "steps",activity:"Active", icon: .activeEnergy, graphData: viewModel.activeEnergyGraph),

            HealthMetric(
                title: "Body Fat",
                value: String(format: "%.1f", viewModel.bodyFatPercentage),
                unit: "%",
                activity: "bodyfat",icon: .bodyFat, graphData: viewModel.bodyFatGraphData
            ),

            HealthMetric(
                title: "Body Mass",
                value: String(format: "%.1f", viewModel.bodyMass),
                unit: "kg",
                activity: "weight",icon: .bodyMass, graphData: viewModel.bodyMassGraphData
            ),

            HealthMetric(
                title: "Height",
                value: String(format: "%.2f", viewModel.height),
                unit: "m",
                activity: "height",icon: .height, graphData: viewModel.heightGraphData
            ),

            HealthMetric(
                title: "Push Count",
                value: "\(Int(viewModel.pushCount))",
                unit: "pushes",
                activity: "pushcount",icon: .pushCount, graphData: viewModel.pushCountGraphData
            ),

            HealthMetric(
                title: "Running Speed",
                value: String(format: "%.2f", viewModel.runningSpeed),
                unit: "m/s",
                activity: "runningspeed",icon: .runningSpeed, graphData: viewModel.runningSpeedGraphData
            ),
            HealthMetric(
                title: "HRV",
                value: String(format: "%.0f", viewModel.hrv),
                unit: "ms",
                activity: "hrv",icon: .hrv, graphData: viewModel.hrvGraph
            ),

            HealthMetric(
                title: "Resting HR",
                value: String(format: "%.0f", viewModel.restingHeartRate),
                unit: "bpm",
                activity: "resting_hr",icon: .restingHR, graphData: viewModel.restingHRGraph
            ),

            HealthMetric(
                title: "Resting Energy",
                value: String(format: "%.0f", viewModel.restingEnergy),
                unit: "cal",
                activity: "resting_hr",icon: .restingEnergy, graphData: viewModel.restingEnergyGraph
            ),
            HealthMetric(
                title: "Walking + Running Distance",
                value: String(format: "%.0f", viewModel.distanceWalkingRunning),
                unit: "mi",
                activity: "resting_hr",icon: .walkingSpeed, graphData: viewModel.distanceGraph
            ),

            HealthMetric(
                title: "Double Suport Time",
                value: String(format: "%.0f", viewModel.walkingDoubleSupport),
                unit: "%",
                activity: "resting_hr",icon: .doubleSupport, graphData: viewModel.doubleSupportGraph
            ),

            HealthMetric(
                title: "Walking Asymmetry",
                value: String(format: "%.0f", viewModel.walkingAsymmetry),
                unit: "%",
                activity: "resting_hr",icon: .walkingAsymmetry, graphData: viewModel.walkingAsymmetryGraph
            ),

            HealthMetric(
                title: "Walking Speed",
                value: String(format: "%.0f", viewModel.walkingSpeed),
                unit: "MPH",
                activity: "resting_hr",icon: .walkingSpeed, graphData: viewModel.walkingSpeedGraph
            ),
            HealthMetric(
                title: "Walking Step Length",
                value: String(format: "%.0f", viewModel.walkingStepLength),
                unit: "in",
                activity: "resting_hr",icon: .stepLength, graphData: viewModel.walkingStepLengthGData
            )
        ]
        LoadDataOnBG().requestAuthorization { authorized in
                           if authorized {
                               print("HealthKit authorized")
                               
                               // Step 2: Enable background delivery
                               LoadDataOnBG().enableBackgroundDelivery()
                               LoadDataOnBG().startObserverQueries()
                               // Optional: Start observer queries here
                           } else {
                               print("HealthKit authorization denied")
                           }
                       }
    }
}
#Preview {
    ContentView()
}
struct GreetingHeaderView: View {
    var userName: String = "Jack"
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hello, \(userName)")
                .font(.system(size: 18, weight: .bold))
            Text("Here's your health data at a glance.")
                .font(.system(size: 13))
                .foregroundColor(.gray)
        }
        .padding(.leading, 5)   // ← Exact 5px left
        .padding(.top, 8)
        .padding(.trailing, 5)  // optional for symmetry
    }
}

struct HealthCard: View {

    let title: String
    let value: String
    let unit: String
    let activity: String
    let icon: HealthIcon
    let graphData: [HealthGraphPoint]

    var body: some View {
        VStack {
            HStack {
                Image(systemName: icon.systemName)
                    .foregroundColor(icon.color)
                    .frame(width: 40, height: 40)
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.leading, 2)

                Spacer()
            }
            HStack {
                Image(systemName: icon.systemName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(icon.color)
                    .frame(width: 50, height: 50)
                    .background(icon.color.opacity(0.2))
                    .clipShape(Circle())
                    .padding(.leading, 5)

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.black)

                    HStack(alignment: .bottom) {
                        Text(value)
                            .font(.system(size: 20, weight: .bold))

                        Text(unit)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.bottom, 2)
                    }
                }
                Spacer()
                HealthGraphMiniView(data: graphData, icon: icon)
            }
            .frame(height: 82)
            .padding(.horizontal, 10)
            .background(Color.healthBackground)
            .cornerRadius(10)
            .shadow(color: .black.opacity(0.04), radius: 6)
            
        }
        .padding()
        .background(.white)
        .cornerRadius(14)
        .clipped()
        .shadow(color: icon.color, radius: 10, x: 0, y: 0)

    }
}

struct HealthGraphMiniView: View {
    @State private var animate = false
    let data: [HealthGraphPoint]
    let icon: HealthIcon

    var body: some View {
        Chart(data) {

            LineMark(
                x: .value("Day", $0.date),
                y: .value("Value", $0.value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(icon.color)
            .lineStyle(StrokeStyle(lineWidth: 2))

            AreaMark(
                x: .value("Day", $0.date),
                y: .value("Value", $0.value)
            )
            .foregroundStyle(icon.color.opacity(0.25))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(width: 120, height: 60)
        
    }
}



