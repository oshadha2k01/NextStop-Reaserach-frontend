# Smart Bus System for Real-Time Passenger Management

## 📌 Project Overview

The *Smart Bus System for Real-Time Passenger Management* is an IoT-driven, intelligent public transport solution designed to improve efficiency, accessibility, and passenger experience in Sri Lanka’s bus network. The system integrates *real-time tracking, passenger occupancy monitoring, mobile interaction, and AI-driven fleet optimization* into a single smart ecosystem.

This project is developed as part of the *IT4010 Research Project – 2025 (July Intake)* under the *Information Technology (IT)* specialization.

---

## 🎯 Main Objectives

* Provide *real-time bus location and accurate ETA predictions*
* Reduce *overcrowding* by monitoring passenger occupancy
* Enable *inclusive and accessible passenger interaction*
* Optimize *routes and fleet usage* using AI-driven analytics

---

## 🧠 System Architecture


+-------------------+        +---------------------+
|   GPS & Sensors   |        | Vision & Thermal    |
| (Bus IoT Module)  |        | Sensors (Onboard)   |
+---------+---------+        +----------+----------+
          |                               |
          v                               v
+--------------------------------------------------+
|          Edge Processing (Arduino / MCU)          |
|  - Data filtering                                |
|  - Temporary buffering                           |
+-------------------+------------------------------+
                    |
                    v
        +----------------------------------+
        |   Cloud Backend & Database       |
        |  - Real-time data ingestion      |
        |  - Historical data storage       |
        +---------+------------------------+
                  |
        +---------+----------+------------------+
        |                    |                  |
        v                    v                  v
+---------------+   +----------------+  +----------------------+
| LSTM ETA      |   | Fleet & Route  |  | Passenger Interaction|
| Prediction ML |   | Optimization   |  | Mobile Application   |
+---------------+   +----------------+  +----------------------+
        \_____________________|_______________________/
                             v
                   Optimized & Smart Bus Service


---

## 🧩 Core Functional Modules

### 1️⃣ IoT-Based Real-Time Bus Tracking & ETA Prediction

*Owner:* Weerakoon W.M.D.P (IT22131560)

*Functionality:*

* GPS-based real-time bus tracking using Arduino
* Hybrid *GSM + Wi-Fi* communication
* Cloud-based data pipeline
* *LSTM machine learning model* for accurate ETA prediction

*Novelty:*

* Context-aware ETA prediction using traffic, weather, and event data
* Low-cost and scalable IoT deployment for developing regions

---

### 2️⃣ Vision-Based Passenger Counting & Occupancy Monitoring

*Owner:* Abeysekara W.R.G.M (IT22271150)

*Functionality:*

* Real-time passenger counting using cctv cameras for both exit and entrance doors. 
* Embedded deep learning models (Yolo12) for human detecting.
* Privacy-preserving anonymous detection

*Novelty:*

* Realtime calculation share with mobile and desktop users.
* No GPU dependency – optimized for embedded systems

---

### 3️⃣ Mobile-Based Passenger Interaction & Accessibility System

*Owner:* Chandrasekara C.M.P.V (IT22286246)

*Functionality:*

* Mobile app for real-time bus updates
* Stop request and seat availability alerts
* Multilingual, audio, and vibration support

*Novelty:*

* Inclusive design for differently-abled users
* Smart travel suggestions based on live occupancy

---
### 4️⃣ Central Fleet Management & Route Optimization Engine

**Owner:** Pathiraja H.P.M.O.N (IT22230492)

#### Functionality
- AI/ML-based prediction model using real-time IoT data to estimate bus arrival time at the passenger’s selected destination before onboarding.
- Dynamic ticket price calculation based on the start and destination locations, using travel distance calculated before the journey begins.
- Live bus tracking with real-time alerts and warnings generated from passenger complaints related to driver behavior.

#### Novelty
- Pre-onboarding AI/ML arrival-time prediction that allows passengers to know the expected travel duration in advance.
- Transparent ticket pricing to reduce corruption and improve driver behavior through real-time passenger feedback and notifications.

---

## 👥 Project Team

| Name                  | Registration Number | Responsibility                  |
| --------------------- | ------------------- | ------------------------------- |
| Weerakoon W.M.D.P     | IT22131560          | IoT Tracking & ETA Prediction   |
| Pathiraja H.P.M.O.N   | IT22230492          | Fleet Management & Optimization |
| Chandrasekara C.M.P.V | IT22286246          | Mobile App & Accessibility      |
| Abeysekara W.R.G.M    | IT22271150          | Passenger Counting & Vision     |

---

## 🛠️ Technologies Used

* *Hardware:* Arduino, GPS, Thermal Sensors, Cameras
* *Networking:* GSM, Wi-Fi
* *Backend:* Cloud Database, REST APIs
* *AI/ML:* LSTM, Tiny-YOLOv3, MobileNet
* *Mobile:* Flutter / Android
* *Analytics:* Python, Data Analytics

---

## 📌 Conclusion

This Smart Bus System introduces a *scalable, intelligent, and inclusive public transport solution* tailored for Sri Lanka. By integrating IoT, AI, computer vision, and mobile technologies, the system enhances reliability, reduces congestion, and improves daily commuting experiences for millions of passengers.

---

📄 This README.md is prepared for academic and project documentation purposes (IT4010 Research Project – 2025)
