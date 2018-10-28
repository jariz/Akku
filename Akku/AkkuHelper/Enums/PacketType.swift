//
//  PacketType.swift
//  AkkuLowLevel
//
//  Created by Jari on 15/10/2018.
//  Copyright © 2018 JARI.IO. All rights reserved.
//

public enum PacketType: UInt8 {
    case HCI_COMMAND = 0x00
    case HCI_EVENT = 0x01
    case SENT_ACL_DATA = 0x02
    case RECV_ACL_DATA = 0x03
    case LMP_SEND = 0x0A
    case LMP_RECV = 0x0B
    case SYSLOG = 0xF7
    case KERNEL = 0xF8
    case KERNEL_DEBUG = 0xF9
    case ERROR = 0xFA
    case POWER = 0xFB
    case NOTE = 0xFC
    case CONFIG = 0xFD
    case NEW_CONTROLLER = 0xFE
}
