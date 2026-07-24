//  HeartModels.swift
//  HeartKit

import Foundation

enum HeartModels: String, CaseIterable, Identifiable {
    case weight = "Weight",
         height = "Height",
         bodyMassIndex = "Body Mass Index",
         restingHeartRate = "Resting Heart Rate",
         bloodPressure = "Blood Pressure",
         cholesterol = "Cholesterol",
         bloodSugar = "Blood Sugar",
         physicalActivity = "Physical Activity",
         smokingStatus = "Smoking Status",
         alcoholConsumption = "Alcohol Consumption",
         stressLevels = "Stress Levels",
         sleepQuality = "Sleep Quality"
    
    var id: String { rawValue }
}
