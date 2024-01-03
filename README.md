# INEL4206 Microprocessors and Embedded Systems - Countdown Timer Project (COREMISE)

## Introduction
This project implements a countdown timer, using the MSP430FR6989 Launchpad. It features a digital display for minutes and seconds and is developed to utilize digital ports, an LCD, interrupt handling, and multiple timers.

## System Description
Coremise displays two different main sections accessible via buttons from a main menu identified by the text `TEAM02`: A list of the teammates of the group that worked on the project and a countdown timer that uses the rightmost four alphanumeric characters of the Launchpad's display.

## System Operation
- The display initially shows the team identifier ("TEAM02").
- Pressing button S1 cycles through the team members' names in alphabetical order.
- Pressing button S2 enters the countdown timer configuration mode, where each digit can be set by pressing S1. The system transitions to a "Ready" state before starting the countdown.
- During counting, pressing S1 doubles the countdown speed, while S2 pauses and resumes the timer. The countdown stops automatically at 00:00.

## Technical Requirements
- The system must utilize Low Power mode and handle button states via interrupt routines.
- Time control should be managed with Timer_A0, avoiding iterative structures.
- The program should be modular, with clearly defined subroutines.
