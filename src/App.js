import { Route, Routes } from "react-router-dom";

import AllAppointmentsPage from "./pages/AllAppointments";
import NewAppointmentPage from "./pages/NewAppointment";
import SavedAppointmentsPage from "./pages/SavedAppointments";
import Layout from "./components/layout/Layout";

function App() {
  return (
    <Layout>
        <Routes>
          <Route exact path='/' element={<AllAppointmentsPage />}/>
          <Route path='/new-appointment' element={<NewAppointmentPage />}/>
          <Route path='/saved-appointments' element={<SavedAppointmentsPage />}/>
        </Routes>
    </Layout>
  );
}

export default App;
