import { useContext } from "react";
import SavedAppointmentsContext from "../store/saved-appointments-context";
import AppointmentList from "../components/appointments/AppointmentList";

function SavedAppointmentsPage() {

    const savedAppointmentsCtx = useContext(SavedAppointmentsContext);

    let content;

    if(savedAppointmentsCtx.totalSavedAppointments === 0) {
        content = <p>You have no saved appointments yet. Book an appointment and save it.</p>
    } else {
        content = <AppointmentList appointments={savedAppointmentsCtx.savedAppointments} />
    }

    return (
        <section>
            <h1>My Saved Appointments</h1>
            {content}
        </section>
    );
}

export default SavedAppointmentsPage;