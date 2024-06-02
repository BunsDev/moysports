import React from 'react';
import ReactDOM from 'react-dom/client';
import './index.css'; 
import HomePage from './HomePage/HomePage'; 
import reportWebVitals from './reportWebVitals';
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <>
  <div className="loadImage"> 
  </div>
  <div className="overlayShade"> 
  </div>

    {/* This is the alias of BrowserRouter i.e. Router */}
    <Router>
      <Routes>
        {/* This route is for home component 
          with exact path "/", in component props 
          we passes the imported component*/}
        <Route
          exact
          path="/"
          element={<HomePage />}
        /> 

        
        {/* If any route mismatches the upper 
          route endpoints then, redirect triggers 
          and redirects app to home component with to="/" */}
        {/* <Redirect to="/" /> */}
        <Route
          path="*"
          element={<Navigate to="/" />}
        />
      </Routes>
    </Router>
  </>
);

// If you want to start measuring performance in your app, pass a function
// to log results (for example: reportWebVitals(console.log))
// or send to an analytics endpoint. Learn more: https://bit.ly/CRA-vitals
reportWebVitals();
