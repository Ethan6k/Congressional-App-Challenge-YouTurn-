//
//  UserProfile.swift
//  TestApp
//
//  Created by Ethan Hong on 7/19/26.
//

import Foundation

class UserProfile: ObservableObject {

    @Published var name = ""
    @Published var age = 18
    
    @Published var sleepHours = 8.0
    @Published var exercise = ""
    @Published var stress = 5
    
    @Published var water = 6
    @Published var screenTime = 4.0
    
    @Published var smoker = false
    @Published var alcohol = false
    
    @Published var goal = ""

}
