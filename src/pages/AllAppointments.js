import { useState, useEffect } from "react";

import AppointmentList from "../components/appointments/AppointmentList";

function AllAppointmentsPage() {
  const [isLoading, setIsLoading] = useState(true);
  const [loadedAppointments, setLoadedAppointments] = useState([]);
  const [error, setError] = useState(null);

  const fetchAppointments = () => {
    setIsLoading(true);
    setError(null);
    
    // Using relative URL that will be handled by Nginx proxy
    fetch("/api/appointments")
      .then((response) => {
        if (!response.ok) {
          throw new Error('Network response was not ok');
        }
        return response.json();
      })
      .then((data) => {
        // MongoDB data already has the required structure with _id
        const appointments = data.map(appointment => ({
          id: appointment._id,  // Map MongoDB _id to id for frontend compatibility
          ...appointment
        }));
        
        setLoadedAppointments(appointments);
        setIsLoading(false);
      })
      .catch((error) => {
        console.error("Error fetching appointments:", error);
        setError(error.message);
        setIsLoading(false);
      });
  };

  useEffect(() => {
    fetchAppointments();
  }, []);

  const handleDeleteAppointment = (deletedAppointmentId) => {
    // Remove the deleted appointment from the state
    setLoadedAppointments(prevAppointments => 
      prevAppointments.filter(appointment => appointment.id !== deletedAppointmentId)
    );
  };

  if (isLoading) {
    return (
      <section>
        <p>Loading...</p>
      </section>
    );
  }

  if (error) {
    return (
      <section>
        <p>Error: {error}</p>
        <button onClick={fetchAppointments}>Try Again</button>
      </section>
    );
  }

  return (
    <section>
      <h1>Available Appointments</h1>
      {loadedAppointments.length === 0 ? (
        <p>No appointments found. Book a new one!</p>
      ) : (
        <AppointmentList 
          appointments={loadedAppointments} 
          onDeleteAppointment={handleDeleteAppointment} 
        />
      )}
    </section>
  );
}

export default AllAppointmentsPage;