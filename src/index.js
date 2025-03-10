import React from "react";
import ReactDOM from "react-dom";
import MeditationScreen from "./components/MeditationScreen";
import "./styles/index.css";

// Create a simple root component
const App = () => {
  return (
    <div className="app">
      <MeditationScreen />
    </div>
  );
};

// Render the app to the root element
const rootElement = document.getElementById("root");
if (rootElement) {
  ReactDOM.render(<App />, rootElement);
} else {
  console.error("Could not find root element to render React app");
}
