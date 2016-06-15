//
//  ViewController.swift
//  sdl-rkx
//
//  Created by James Kizer on 04/28/2016.
//  Copyright (c) 2016 Cornell Tech Foundry. All rights reserved.
//

import UIKit
import ResearchKit
import sdl_rkx

let kActivityIdentifiers = "activity_identifiers"
let kMedicationIdentifiers = "medication_identifiers"

class ViewController: UIViewController, ORKTaskViewControllerDelegate {
    
    // MARK: Properties
    
    /**
     When a task is completed, the `TaskListViewController` calls this closure
     with the created task.
     */
    var taskResultFinishedCompletionHandler: (ORKResult -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func storeActivitiesForSpotAssessment(activities: [String]) {
        NSUserDefaults().setObject(activities, forKey: kActivityIdentifiers)
    }
    
    func loadActivitiesForSpotAssessment() -> [String]? {
        return NSUserDefaults().arrayForKey(kActivityIdentifiers) as? [String]
    }
    
    func storeMedicationsForSpotAssessment(medications: [String]) {
        NSUserDefaults().setObject(medications, forKey: kMedicationIdentifiers)
    }
    
    func loadMedicationsForSpotAssessment() -> [String]? {
        return NSUserDefaults().arrayForKey(kMedicationIdentifiers) as? [String]
    }
    
    
    
    
    
    // MARK: ORKTaskViewControllerDelegate
    
    func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
        
        if reason == ORKTaskViewControllerFinishReason.Completed {
            //if YADL full task, extract results and store for filtering
            if let _ = taskViewController.task as? YADLFullAssessmentTask,
                let results:[ORKChoiceQuestionResult] = YADLFullAssessmentTask.fullAssessmentResults(taskViewController.result)
            {
                print(results)
                let activityIdentifiers:[String] = results.filter { result  in
                    
                    guard let choiceAnswers = result.choiceAnswers
                        else {
                            return false
                    }
                    if choiceAnswers.count == 1,
                        let answer = choiceAnswers[0] as? String {
                        return (answer == "hard") || (answer == "moderate")
                    }
                    else {
                        return false
                    }
                    }
                    .map { $0.identifier }
                self.storeActivitiesForSpotAssessment(activityIdentifiers)
            }
            //if YADL full task, extract results and store for filtering
            if let _ = taskViewController.task as? MEDLFullAssessmentTask,
                let results:[ORKChoiceQuestionResult] = MEDLFullAssessmentTask.fullAssessmentResults(taskViewController.result)
            {
                print(results)
                let copingIdentifiers: [String] = results.reduce([], combine: { (acc, result) -> [String] in
                    if let identifiers = result.answer as? [String] {
                        return acc + identifiers
                    }
                    else {
                        return acc
                    }
                })
                self.storeMedicationsForSpotAssessment(copingIdentifiers)
            }
            else if let _ = taskViewController.task as? PAMTask {
                print(taskViewController.result)
            }
        }
        
        taskViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    

    func launchAssessmentForTask(task: ORKOrderedTask) {
        /*
         Passing `nil` for the `taskRunUUID` lets the task view controller
         generate an identifier for this run of the task.
         */
        let taskViewController = ORKTaskViewController(task: task, taskRunUUID: nil)
        
        // Make sure we receive events from `taskViewController`.
        taskViewController.delegate = self
        
        // Assign a directory to store `taskViewController` output.
        taskViewController.outputDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        
        /*
         We present the task directly, but it is also possible to use segues.
         The task property of the task view controller can be set any time before
         the task view controller is presented.
         */
        presentViewController(taskViewController, animated: true, completion: nil)
    }
    @IBAction func launchPAM(sender: AnyObject) {
        
        let task = PAMTask(identifier: "PAM identifier")
        
        self.launchAssessmentForTask(task)
        
    }
    @IBAction func launchYADLFullAssessment(sender: AnyObject) {
        
        //create a YADL full assessment task
        let task = YADLFullAssessmentTask(identifier: "YADL Full Assessment Identifier", propertiesFileName: "YADL")
        
        self.launchAssessmentForTask(task)
    }
    
    @IBAction func launchYADLSpotAssessment(sender: AnyObject) {
        //create a YADL spot assessment task
//        let task = YADLSpotAssessmentTask(identifier: "YADL Spot Assessment Identifier", propertiesFileName: "YADL")
        let task = YADLSpotAssessmentTask(identifier: "YADL Spot Assessment Identifier", propertiesFileName: "YADL", activityIdentifiers: self.loadActivitiesForSpotAssessment())
        
        self.launchAssessmentForTask(task)
    }
    
    @IBAction func launchMEDLFullAssessment(sender: AnyObject) {
        let task = MEDLFullAssessmentTask(identifier: "MEDL Full Assessment Identifier", propertiesFileName: "MEDL")
        
        self.launchAssessmentForTask(task)
    }
    
    @IBAction func launchMEDLSpotAssessment(sender: AnyObject) {
        let task = MEDLSpotAssessmentTask(identifier: "MEDL Spot Assessment", propertiesFileName: "MEDL", itemIdentifiers: self.loadMedicationsForSpotAssessment())
        
        self.launchAssessmentForTask(task)
    }
    @IBAction func launchMySurvey(sender: AnyObject) {
        let task = YADLFullAssessmentTask(identifier: "My Survey Identifier", propertiesFileName: "mySurvey")
        
        self.launchAssessmentForTask(task)

        
    }
    
}

