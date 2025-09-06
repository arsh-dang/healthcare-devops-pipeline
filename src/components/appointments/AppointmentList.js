import AppointmentItem from "./AppointmentItem";
import classes from "./AppointmentList.module.css";

function AppointmentList(props) {
  return (
    <ul className={classes.list}>
      {props.appointments.map((appointment) => (
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
        />
      ))}
    </ul>
  );
}

export default AppointmentList;
