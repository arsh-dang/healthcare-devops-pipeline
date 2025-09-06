import { Link } from "react-router-dom";

import classes from "./MainNavigation.module.css";
import SavedAppointmentsContext from "../../store/saved-appointments-context";
import { useContext } from "react";
import healthcareLogo from "../ui/logo/healthcare-logo.svg";

function MainNavigation() {
  const savedAppointmentsCtx = useContext(SavedAppointmentsContext);

  return (
    <header className={classes.header}>
      <div className={classes.logoContainer}>
        <img src={healthcareLogo} alt="Healthcare Logo" className={classes.logoImage} />
        <div className={classes.logoText}>Healthcare Appointments</div>
      </div>
      <nav>
        <ul>
          <li>
            <Link to="/">All Appointments</Link>
          </li>
          <li>
            <Link to="/new-appointment">
              Book Appointment
            </Link>
          </li>
          <li>
            <Link to="/saved-appointments">
              Saved Appointments
              <span className={classes.badge}>{savedAppointmentsCtx.totalSavedAppointments}</span>
            </Link>
          </li>
        </ul>
      </nav>
    </header>
  );
}

export default MainNavigation;
