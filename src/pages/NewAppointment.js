import { useState } from "react";
import AppointmentForm from "../components/appointments/AppointmentForm";
import { useNavigate } from "react-router-dom";

function NewAppointmentPage() {
    const navigate = useNavigate();
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [error, setError] = useState(null);

    function onAddAppointmentHandler(appointmentData) {
        setIsSubmitting(true);
        setError(null);

                // Using 127.0.0.1 for API calls
        fetch('http://127.0.0.1:5001/api/appointments', {
            method: 'POST',
            body: JSON.stringify(appointmentData),
            headers: {
                'Content-Type': 'application/json'
            }
        })
        .then(response => {
            setIsSubmitting(false);
            if (!response.ok) {
                throw new Error('Failed to create appointment');
            }
            return response.json();
        })
        .then(() => {
            navigate('/');
        })
        .catch(error => {
            setError(error.message || 'Something went wrong');
            setIsSubmitting(false);
        });
    }

    return (
        <section>
            <h1>Book New Appointment</h1>
            {error && <div className="error-message">{error}</div>}
            <AppointmentForm 
                onAddAppointment={onAddAppointmentHandler} 
                disabled={isSubmitting}
            />
            {isSubmitting && <p>Submitting appointment data...</p>}
        </section>
    );
}

export default NewAppointmentPage;