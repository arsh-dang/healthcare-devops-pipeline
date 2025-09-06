import { useContext, useState } from "react";
import PropTypes from 'prop-types';

import Card from "../ui/Card";
import classes from "./AppointmentItem.module.css";
import SavedAppointmentsContext from "../../store/saved-appointments-context";

function AppointmentItem(props) {
  const savedAppointmentsCtx = useContext(SavedAppointmentsContext);
  const [isDeleting, setIsDeleting] = useState(false);

  const appointmentIsSaved = savedAppointmentsCtx.isAppointmentSaved(props.id);

  function toggleSaveStatusHandler() {
    if (appointmentIsSaved) {
      savedAppointmentsCtx.removeAppointment(props.id);
    } else {
      savedAppointmentsCtx.saveAppointment({
        id: props.id,
        title: props.title,
        description: props.description,
        image: props.image,
        address: props.address,
        doctor: props.doctor,
        doctorSpecialty: props.doctorSpecialty,
        clinicName: props.clinicName,
        dateTime: props.dateTime
      });
    }
  }

  function deleteAppointmentHandler() {
    if (window.confirm("Are you sure you want to delete this appointment? This action cannot be undone.")) {
      setIsDeleting(true);
      
      // Using relative URL that will be handled by Nginx proxy
      fetch(`/api/appointments/${props.id}`, {
        method: 'DELETE',
      })
      .then(response => {
        if (!response.ok) {
          throw new Error('Failed to delete appointment');
        }
        return response.json();
      })
      .then(() => {
        // If the appointment was also saved, remove it from saved appointments
        if (appointmentIsSaved) {
          savedAppointmentsCtx.removeAppointment(props.id);
        }
        // Call the onDelete prop to notify parent component
        if (props.onDelete) {
          props.onDelete(props.id);
        }
      })
      .catch(error => {
        console.error("Error deleting appointment:", error);
        alert("Failed to delete appointment. Please try again.");
      })
      .finally(() => {
        setIsDeleting(false);
      });
    }
  }

  // Format date and time if available
  const formattedDateTime = props.dateTime ? 
    new Date(props.dateTime).toLocaleString('en-US', {
      weekday: 'short',
      year: 'numeric',
      month: 'short',
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    }) : '';

  return (
    <li className={classes.item} data-testid={`appointment-item-${props.id}`}>
      <Card>
        <div className={classes.image}>
          <img src={props.image} alt={props.clinicName || props.title} />
        </div>
        <div className={classes.content}>
          <h3>{props.title}</h3>
          <h4>{props.clinicName}</h4>
          <address>{props.address}</address>
          {formattedDateTime && <p className={classes.datetime}><strong>Appointment:</strong> {formattedDateTime}</p>}
          <p className={classes.doctor}><strong>Doctor:</strong> {props.doctor} {props.doctorSpecialty && `(${props.doctorSpecialty})`}</p>
          <p>{props.description}</p>
        </div>
        <div className={classes.buttonContainer}>
          <button
            onClick={toggleSaveStatusHandler}
            className={classes.actions}
            disabled={isDeleting}
          >
            {appointmentIsSaved ? "Remove from Saved" : "Save Appointment"}
          </button>
          
          <button
            onClick={deleteAppointmentHandler}
            className={`${classes.actions} ${classes.deleteButton}`}
            disabled={isDeleting}
          >
            {isDeleting ? "Deleting..." : "Delete Appointment"}
          </button>
        </div>
      </Card>
    </li>
  );
}

AppointmentItem.propTypes = {
  id: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  description: PropTypes.string,
  image: PropTypes.string.isRequired,
  address: PropTypes.string.isRequired,
  doctor: PropTypes.string.isRequired,
  doctorSpecialty: PropTypes.string,
  clinicName: PropTypes.string.isRequired,
  dateTime: PropTypes.string,
  onDelete: PropTypes.func
};

export default AppointmentItem;
