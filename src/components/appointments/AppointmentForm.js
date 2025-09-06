import { useRef, useState, useEffect } from "react";

import Card from "../ui/Card";
import classes from "./AppointmentForm.module.css";
import { CLINICS, DOCTORS } from "../../utils/clinicData";

function AppointmentForm(props) {
  const titleInputRef = useRef();
  const descriptionInputRef = useRef();
  const dateTimeInputRef = useRef();
  
  const [selectedClinic, setSelectedClinic] = useState('c1');
  const [availableDoctors, setAvailableDoctors] = useState([]);
  const [selectedDoctor, setSelectedDoctor] = useState('');

  // Update available doctors when clinic changes
  useEffect(() => {
    setAvailableDoctors(DOCTORS[selectedClinic] || []);
    if (DOCTORS[selectedClinic] && DOCTORS[selectedClinic].length > 0) {
      setSelectedDoctor(DOCTORS[selectedClinic][0].id);
    }
  }, [selectedClinic]);

  function submitHandler(event) {
    event.preventDefault();

    const enteredTitle = titleInputRef.current.value;
    const enteredDescription = descriptionInputRef.current.value;
    const enteredDateTime = dateTimeInputRef.current.value;
    
    // Get selected clinic and doctor data
    const clinic = CLINICS.find(c => c.id === selectedClinic);
    const doctor = availableDoctors.find(d => d.id === selectedDoctor);

    const appointmentData = {
      title: enteredTitle,
      description: enteredDescription,
      dateTime: enteredDateTime,
      clinic: selectedClinic,
      clinicName: clinic.name,
      image: clinic.image,
      address: clinic.address,
      doctor: doctor.name,
      doctorSpecialty: doctor.specialty
    };

    props.onAddAppointment(appointmentData);
  }

  function handleClinicChange(event) {
    setSelectedClinic(event.target.value);
  }

  function handleDoctorChange(event) {
    setSelectedDoctor(event.target.value);
  }

  return (
    <Card>
      <form className={classes.form} onSubmit={submitHandler}>
        <div className={classes.control}>
          <label htmlFor="title">Appointment Type</label>
          <input 
            type="text" 
            required 
            id="title" 
            ref={titleInputRef} 
            placeholder="e.g., Annual Check-up, Consultation" 
            disabled={props.disabled}
          />
        </div>
        
        <div className={classes.control}>
          <label htmlFor="clinic">Select Clinic</label>
          <select 
            id="clinic" 
            value={selectedClinic} 
            onChange={handleClinicChange} 
            required
            disabled={props.disabled}
          >
            {CLINICS.map(clinic => (
              <option key={clinic.id} value={clinic.id}>
                {clinic.name} - {clinic.address}
              </option>
            ))}
          </select>
        </div>
        
        <div className={classes.control}>
          <label htmlFor="doctor">Select Doctor</label>
          <select 
            id="doctor" 
            value={selectedDoctor} 
            onChange={handleDoctorChange} 
            required
            disabled={props.disabled}
          >
            {availableDoctors.map(doctor => (
              <option key={doctor.id} value={doctor.id}>
                {doctor.name} - {doctor.specialty}
              </option>
            ))}
          </select>
        </div>
        
        <div className={classes.control}>
          <label htmlFor="dateTime">Date & Time</label>
          <input 
            type="datetime-local" 
            required 
            id="dateTime" 
            ref={dateTimeInputRef}
            disabled={props.disabled} 
          />
        </div>
        
        <div className={classes.control}>
          <label htmlFor="description">Notes</label>
          <textarea
            id="description"
            required
            rows="5"
            ref={descriptionInputRef}
            placeholder="Any special requirements or information about your visit"
            disabled={props.disabled}
          ></textarea>
        </div>
        
        <div className={classes.actions}>
          <button disabled={props.disabled}>
            {props.disabled ? 'Submitting...' : 'Book Appointment'}
          </button>
        </div>
      </form>
    </Card>
  );
}

export default AppointmentForm;
