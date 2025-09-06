import React from "react";
import PropTypes from "prop-types";
import AppointmentItem from "./AppointmentItem";
import classes from "./AppointmentList.module.css";

function AppointmentList(props) {
  const appointments = props.appointments || [];
  
  if (appointments.length === 0) {
    return (
      <div className={classes.empty}>
        <p>No appointments found.</p>
      </div>
    );
  }

  return (
    <ul className={classes.list}>
      {appointments.map((appointment) => (
        <AppointmentItem
          key={appointment.id}
          id={appointment.id}
          image={appointment.image}
          title={appointment.title}
          address={appointment.address}
          description={appointment.description}
          doctor={appointment.doctor}
          doctorSpecialty={appointment.doctorSpecialty}
          clinicName={appointment.clinicName}
          dateTime={appointment.dateTime}
          onDelete={props.onDeleteAppointment}
          data-testid={`appointment-item-${appointment.id}`}
        />
      ))}
    </ul>
  );
}

AppointmentList.propTypes = {
  appointments: PropTypes.arrayOf(
    PropTypes.shape({
      id: PropTypes.string.isRequired,
      image: PropTypes.string,
      title: PropTypes.string,
      address: PropTypes.string,
      description: PropTypes.string,
      doctor: PropTypes.string,
      doctorSpecialty: PropTypes.string,
      clinicName: PropTypes.string,
      dateTime: PropTypes.string,
    })
  ),
  onDeleteAppointment: PropTypes.func,
};

AppointmentList.defaultProps = {
  appointments: [],
  onDeleteAppointment: () => {},
};

export default AppointmentList;
