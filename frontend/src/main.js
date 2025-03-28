import "./style.css";
import { gsap } from "gsap";
import { createAnimationCallToActionScreen, createAnimationPercentageBarScreen, createAnimationGoalScreen } from "./animations.js";

// Settings
const SLIDE_DURATION_MS = 8000;

// State variables
let currentScreen = 0;
let percentage = 0;
let goals = [];
let animations = [];

const backendUrl = import.meta.env.VITE_BACKEND_URL

document.addEventListener("DOMContentLoaded", async () => {
  if (await loadFromAPI()) {
    // Add new elements to DOM
    createDOMElementsForGoals();
    createDOMElementsForPercentage();

    // Load all animations
    animations = [
      createAnimationCallToActionScreen(),
      createAnimationPercentageBarScreen(percentage),
      createAnimationGoalScreen(),
    ];

    // Start the animation loop
    animations[currentScreen].play();
    setInterval(screenLoop, SLIDE_DURATION_MS);
  } else {
    // Display error screen
    document.querySelector("#error-screen").style.display = "flex";
    document.querySelectorAll('.screen').forEach((screen) => screen.style.display = "none");
  }
});

/**
 * Main loop for the animations.
 */
function screenLoop() {
  currentScreen = (currentScreen + 1) % 3;

  // Slide to the next screen
  gsap.to(".screen-container", {
    x: `-${currentScreen * 100}vw`,
    duration: 1,
    ease: "power2.inOut",
    onComplete: () => {
      // Reset all animations and play next
      animations.forEach((animation) => animation.reset());
      animations[currentScreen].play();
    },
  });
}

/**
 * Call the API and fetch all the goals and the current percentage.
 */
async function loadFromAPI() {
  let success = true;

  try {
    const response = await fetch(`${backendUrl}/api/percentage`);
    percentage = (await response.json()).percentage;
  } catch (error) {
    console.error("Error fetching percentage data:", error);
    success = false;
  }

  try {
    const response = await fetch(`${backendUrl}/api/goals`);
    goals = await response.json();
  } catch (error) {
    console.error("Error fetching goals data:", error);
    success = false;
  }

  return success;
}

/**
 * Creates all cards for the goals.
 */
function createDOMElementsForGoals() {
  const list = document.querySelector(".goals-list");
  list.innerHTML = "";
  goals.forEach((goal) => {
    const applicableBackgroundClasses = percentage >= goal.targetPercentage ? "bg-lime-500" : "bg-rose-700";
    const applicableTextClasses = percentage >= goal.targetPercentage ? "text-lime-500" : "text-rose-700";
    list.innerHTML += `
      <div class="card text-3x flex items-center text-left drop-shadow-lg font-bold ${applicableBackgroundClasses}">
        <div class="bg-white ${applicableTextClasses} rounded-lg m-1 mr-3 p-2 pt-0 drop-shadow-md">${goal.targetPercentage}%</div>
        <div class="pb-3">${goal.name}</div>
      </div>`;
  });
}

/**
 * Sets percentage text in the DOM elements.
 */
function createDOMElementsForPercentage() {
  const percentageElem = document.querySelector(".percentage");
  percentageElem.textContent = percentage + "%";
}
