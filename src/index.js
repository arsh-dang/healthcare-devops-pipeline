import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter } from "react-router-dom";

import "./index.css";
import App from "./App";
import { SavedAppointmentsProvider } from "./store/saved-appointments-context";

const root = ReactDOM.createRoot(document.getElementById("root"));
root.render(
  <SavedAppointmentsProvider>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </SavedAppointmentsProvider>
);
