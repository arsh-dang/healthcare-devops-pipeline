import { useState } from "react";
import { createContext } from "react";
import PropTypes from 'prop-types';

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
            // Check if appointment with same ID already exists
            const existingAppointment = prevSavedAppointments.find(app => app.id === appointment.id);
            if (existingAppointment) {
                // Don't add duplicate, return existing array
                return prevSavedAppointments;
            }
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

SavedAppointmentsProvider.propTypes = {
    children: PropTypes.node.isRequired
};

export default SavedAppointmentsContext;