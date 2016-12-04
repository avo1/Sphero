//
//  DroneCmd.swift
//  CoDrone
//
//  Created by Dave Vo on 12/4/16.
//  Copyright © 2016 DaveVo. All rights reserved.
//

import UIKit

class DroneCmd: NSObject {
    
    static let batteryCheckFrequency: Double = 10.0   // every 10s
    static let batteryCriticalLevel: UInt8 = 35
    
    // Frequently used commands
    static let takeOffCmd  = [DataType.Command.rawValue, CommandType.FlightEvent.rawValue, FlightEvent.TakeOff.rawValue]
    static let landingCmd  = [DataType.Command.rawValue, CommandType.FlightEvent.rawValue, FlightEvent.Landing.rawValue]
    static let estopCmd    = [DataType.Command.rawValue, CommandType.FlightEvent.rawValue, FlightEvent.Stop.rawValue]
    static let checkBatteryCmd = [DataType.Request.rawValue, DataType.State.rawValue]
    
    static func flightCommand() -> [UInt8] {
        return [0x00]
    }
    
    
    /************************************************************************************/
    /*                      Data to be transferred to the drone                         */
 
    enum DataType: UInt8 {
        case    None = 0,
        // system information
                Ping,                   ///<	check communication(reserved)
                Ack,                    ///<	response to	receiving data
                Error,                  ///<	error(reserved)
                Request,                ///<	data request
                Passcode                ///<	reset password for pairing
        
        // control, command
        case    Control	= 0x10,         ///<	control
                Command,                ///<	command
                Command2,               ///<	multiple command (command	1,	2)
                Command3                ///<	multiple command (command	1,	2,	3)
        
        // LED
        case    LedMode	= 0x20,         ///<    set	single LED	mode
                LedMode2,               ///<	set	double LED	mode
                LedModeCommand,         ///<	LED	mode, command
                LedModeCommandIr,       ///<	LED	mode, command, IR data transfer
                LedModeColor,           ///<    LED	mode, set single RGB color respectively
                LedModeColor2,          ///<	LED	mode, set double RGB color respectively
                LedEvent,               ///<	single LED event
                LedEvent2,              ///<	double LED event
                LedEventCommand,        ///<	LED	event, command
                LedEventCommandIr,      ///<	LED	event, command, IR data transfer
                LedEventColor,          ///<	LED	event, set single RGB color respectively
                LedEventColor2,         ///<	LED	event, set double RGB color respectively
                LedModeDefaultColor,    ///<	LED	default	mode, set single RGB color respectively
                LedModeDefaultColor2    ///<	LED	default	mode, set double RGB color respectively
        
        // drone condition
        case    Address	= 0x30,         ///<	IEEE address
                State,                  ///<	state(flight mode, coordinate, battery)
                Attitude,               ///<	attitude
                GyroBias,               ///<	gyro bias
                TrimAll,                ///<	fine adjustment
                TrimFlight,             ///<	fine adjustment	in flight mode
                TrimDrive               ///<    fine adjustment	in drive mode
        
        //	data transfer
        case    IrMessage = 0x40        ///<	IR data transfer
        
        //	Sensor
        case    ImuRawAndAngle = 0x50,  ///<	IMU	raw	data, Angle
                Pressure,               ///<	pressure sensor data
                ImageFlow,              ///<	optical	flow sensor
                Button,                 ///<	button input
                Battery,                ///<	battery
                Motor,                  ///<	motor control input vales
                Temperature             ///<	temperature
    }
    
    /************************************************************************************/
    
    enum CommandType: UInt8 {
        case    None	= 0                 ///<	no event
        //	setting
        case    ModePetrone = 0x10      ///<	change petrone mode
        //	control
        case    Coordinate = 0x20,      ///<	change coordinate
                Trim,                   ///<	change fine	adjustment value
                FlightEvent,            ///<	execute	flight event
                DriveEvent,             ///<	execute	drive event
                Stop                    ///<	stop
        // reset
        case    ResetHeading = 0x50,    ///<	Reset heading
                ClearGyroBiasAndTrim    ///<	Reset gyrobias and fine adjustment value
        
        //	connection
        case    PairingActivate = 0x80, ///<	enable pairing
                PairingDeactivate,      ///<	disable pairing
                TerminateConnection     ///<    connection terminates
        //	request
        case    Request	= 0x90          ///<	request data
    }
    
    /************************************************************************************/
    
    enum FlightEvent: UInt8 {
        case    None = 0,
                TakeOff,                ///<	takeoff
                FlipFront,              ///<	flip
                FlipRear,               ///<	flip
                FlipLeft,               ///<	flip
                FlipRight,              ///<	flip
                Stop,                   ///<	stop
                Landing,                ///<	landing
                Reverse,                ///<	turtle turn
                Shot,                   ///<	motion when shooting
                UnderAttack,            ///<	motion under attack
                Square,                 ///<	square flight
                CircleLeft,             ///<	circle flight(left)
                CircleRight,            ///<	circle flight(right)
                Rotate180               ///<	rotate 180 degrees
    }
    
    /************************************************************************************/
    
}
