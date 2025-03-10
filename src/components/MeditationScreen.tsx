import React, { useState, useEffect } from "react";
import PresetSelector from "./PresetSelector";
import { MeditationPreset } from "../models/MeditationPreset";
import "../styles/PresetSelector.css";

const MeditationScreen: React.FC = () => {
  const [activePreset, setActivePreset] = useState<MeditationPreset | null>(
    null
  );
  const [isRunning, setIsRunning] = useState(false);
  const [currentPhase, setCurrentPhase] = useState<
    "inhale" | "hold-inhale" | "exhale" | "hold-exhale"
  >("inhale");
  const [timer, setTimer] = useState<number>(0);
  const [progress, setProgress] = useState<number>(0);
  const [cycleCount, setCycleCount] = useState<number>(0);

  useEffect(() => {
    console.log("MeditationScreen mounted");
    console.log(
      "Is PresetSelector being rendered:",
      !activePreset || !isRunning
    );

    // Cleanup timer on unmount
    return () => {
      if (timer) {
        clearInterval(timer);
      }
    };
  }, []);

  const handleSelectPreset = (preset: MeditationPreset) => {
    console.log("Preset selected:", preset);
    setActivePreset(preset);
    setIsRunning(false); // Reset any running meditation
    setCurrentPhase("inhale");
    setProgress(0);
    setCycleCount(0);

    // Clear any existing timer
    if (timer) {
      clearInterval(timer);
      setTimer(0);
    }
  };

  const startMeditation = () => {
    if (activePreset) {
      console.log("Starting meditation with preset:", activePreset);
      setIsRunning(true);

      // Initialize the first phase
      setCurrentPhase("inhale");
      setProgress(0);

      // Start the timer to run the animation
      const intervalId = window.setInterval(() => {
        updateBreathingCycle();
      }, 100); // Update every 100ms for smooth animation

      setTimer(intervalId);
    }
  };

  const updateBreathingCycle = () => {
    setProgress((prevProgress) => {
      let newProgress = prevProgress + 0.1;

      // If we've completed the current phase
      if (newProgress >= 1) {
        newProgress = 0;

        // Move to next phase
        if (currentPhase === "inhale") {
          if (
            activePreset?.holdInhaleSeconds &&
            activePreset.holdInhaleSeconds > 0
          ) {
            setCurrentPhase("hold-inhale");
          } else {
            setCurrentPhase("exhale");
          }
        } else if (currentPhase === "hold-inhale") {
          setCurrentPhase("exhale");
        } else if (currentPhase === "exhale") {
          if (
            activePreset?.holdExhaleSeconds &&
            activePreset.holdExhaleSeconds > 0
          ) {
            setCurrentPhase("hold-exhale");
          } else {
            setCurrentPhase("inhale");
            // Completed a full cycle
            setCycleCount((prev) => {
              const newCount = prev + 1;
              // Check if we've reached the target number of rounds
              if (activePreset?.rounds && newCount >= activePreset.rounds) {
                stopMeditation();
              }
              return newCount;
            });
          }
        } else if (currentPhase === "hold-exhale") {
          setCurrentPhase("inhale");
          // Completed a full cycle
          setCycleCount((prev) => {
            const newCount = prev + 1;
            // Check if we've reached the target number of rounds
            if (activePreset?.rounds && newCount >= activePreset.rounds) {
              stopMeditation();
            }
            return newCount;
          });
        }
      }

      return newProgress;
    });
  };

  const stopMeditation = () => {
    if (timer) {
      clearInterval(timer);
      setTimer(0);
    }
    setIsRunning(false);
  };

  const getPhaseInstruction = (): string => {
    switch (currentPhase) {
      case "inhale":
        return "Breathe In";
      case "hold-inhale":
        return "Hold";
      case "exhale":
        return "Breathe Out";
      case "hold-exhale":
        return "Hold";
      default:
        return "Breathe";
    }
  };

  const getCurrentPhaseTime = (): number => {
    if (!activePreset) return 0;

    switch (currentPhase) {
      case "inhale":
        return activePreset.inhaleSeconds * (1 - progress);
      case "hold-inhale":
        return activePreset.holdInhaleSeconds * (1 - progress);
      case "exhale":
        return activePreset.exhaleSeconds * (1 - progress);
      case "hold-exhale":
        return activePreset.holdExhaleSeconds * (1 - progress);
      default:
        return 0;
    }
  };

  // Calculate the size of the breathing circle based on the current phase and progress
  const getCircleScale = (): number => {
    if (!activePreset) return 1;

    switch (currentPhase) {
      case "inhale":
        return 0.8 + progress * 0.2; // Scale from 0.8 to 1.0
      case "hold-inhale":
        return 1.0; // Fully expanded
      case "exhale":
        return 1.0 - progress * 0.2; // Scale from 1.0 to 0.8
      case "hold-exhale":
        return 0.8; // Fully contracted
      default:
        return 1;
    }
  };

  return (
    <div
      className="meditation-screen"
      style={{
        backgroundColor: "#f0f0f0",
        minHeight: "100vh",
        padding: "20px",
        color: "#333",
      }}
    >
      <h1 style={{ marginBottom: "20px", color: "#222" }}>Meditation Screen</h1>

      {!activePreset || !isRunning ? (
        <PresetSelector onSelectPreset={handleSelectPreset} />
      ) : (
        <div
          className="meditation-active"
          style={{
            padding: "20px",
            backgroundColor: "#fff",
            borderRadius: "8px",
            boxShadow: "0 2px 10px rgba(0,0,0,0.1)",
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            justifyContent: "center",
            minHeight: "60vh",
          }}
        >
          <h2>{activePreset.name}</h2>
          <div style={{ margin: "30px 0" }}>
            <div
              style={{
                position: "relative",
                width: "250px",
                height: "250px",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
              }}
            >
              {/* Progress ring */}
              <svg width="250" height="250" viewBox="0 0 100 100">
                <circle
                  cx="50"
                  cy="50"
                  r="45"
                  fill="none"
                  stroke="#e0e0e0"
                  strokeWidth="2"
                />
                <circle
                  cx="50"
                  cy="50"
                  r="45"
                  fill="none"
                  stroke="#3498db"
                  strokeWidth="3"
                  strokeDasharray="283"
                  strokeDashoffset={283 * (1 - progress)}
                  transform="rotate(-90 50 50)"
                />
              </svg>

              {/* Breathing circle */}
              <div
                style={{
                  position: "absolute",
                  width: "70%",
                  height: "70%",
                  borderRadius: "50%",
                  backgroundColor: "#3498db33",
                  transform: `scale(${getCircleScale()})`,
                  transition: "transform 0.1s ease-in-out",
                }}
              />

              {/* Instruction text */}
              <div
                style={{
                  position: "absolute",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  justifyContent: "center",
                  backgroundColor: "rgba(255, 255, 255, 0.7)",
                  borderRadius: "50%",
                  width: "120px",
                  height: "120px",
                  boxShadow: "0 2px 10px rgba(0,0,0,0.05)",
                }}
              >
                <div
                  style={{
                    fontSize: "24px",
                    fontWeight: "bold",
                    color: "#333",
                  }}
                >
                  {getPhaseInstruction()}
                </div>
                <div
                  style={{
                    fontSize: "32px",
                    fontFamily: "monospace",
                    marginTop: "8px",
                    color: "#3498db",
                  }}
                >
                  {getCurrentPhaseTime().toFixed(1)}
                </div>
              </div>
            </div>
          </div>

          <div
            style={{
              marginBottom: "20px",
              backgroundColor: "#f0f0f0",
              padding: "8px 16px",
              borderRadius: "20px",
              fontWeight: "500",
              color: "#444",
            }}
          >
            Cycle: {cycleCount + 1} of {activePreset.rounds || "∞"}
          </div>

          <button
            onClick={stopMeditation}
            style={{
              backgroundColor: "#e74c3c",
              color: "white",
              padding: "12px 24px",
              border: "none",
              borderRadius: "8px",
              marginTop: "20px",
              cursor: "pointer",
              fontWeight: "600",
              boxShadow: "0 2px 8px rgba(231, 76, 60, 0.3)",
            }}
          >
            Stop Meditation
          </button>
        </div>
      )}

      {activePreset && !isRunning && (
        <button
          className="start-button"
          onClick={startMeditation}
          style={{
            backgroundColor: "#27ae60",
            color: "white",
            padding: "12px 24px",
            border: "none",
            borderRadius: "4px",
            marginTop: "20px",
            fontSize: "16px",
            cursor: "pointer",
          }}
        >
          Start {activePreset.name}
        </button>
      )}
    </div>
  );
};

export default MeditationScreen;
