import { useState } from "react";
import { createContext } from "react";

const SavedAppointmentsContext = createContext({
    savedAppointments: [],
    totalSavedAppointments: 0,
    saveAppointment: (appointment) => {},
    removeAppointment: (appointmentId) => {},
    isAppointmentSaved: (appointmentId) => {}
});

export function SavedAppointmentsProvider(props) {
    
    const [userSavedAppointments, setUserSavedAppointments] = useState([]);

    function saveAppointmentHandler(appointment){
        setUserSavedAppointments((prevSavedAppointments) => {
            return prevSavedAppointments.concat(appointment);
        });
    }

    function removeAppointmentHandler(appointmentId){
        setUserSavedAppointments(prevSavedAppointments => {
            return prevSavedAppointments.filter(appointment => appointment.id !== appointmentId);
        });
    }

    function isAppointmentSavedHandler(appointmentId){
        return userSavedAppointments.some(appointment => appointment.id === appointmentId);
    }

    const context = {
        savedAppointments: userSavedAppointments,
        totalSavedAppointments: userSavedAppointments.length,
        saveAppointment: saveAppointmentHandler,
        removeAppointment: removeAppointmentHandler,
        isAppointmentSaved: isAppointmentSavedHandler
    };
    
    return (
        <SavedAppointmentsContext.Provider value={context}>
            {props.children}
        </SavedAppointmentsContext.Provider>
    );
}

export default SavedAppointmentsContext;