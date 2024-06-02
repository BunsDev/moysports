// Modal.js
import React, { useState } from 'react';
import './Modal.css';

const Modal = ({ show, handleClose, teams, handleBet }) => {

  const [selected, setSelected] = useState(0);
  if (!show) {
    return null;
  }

  const handleSelection = (event) => {
    setSelected(event.target.value);
  };

  return (
    <div className="modal-overlay">
      <div className="modal">
        <div className="modal-header">
          <h2>Test your knowledge</h2>
          <button onClick={handleClose} className="close-button">&times;</button>
        </div>
        <div className="modal-body">
          <label>
            <input type="radio" name="team" value="0" onChange={handleSelection} />
            {teams.title.split("vs")[0].trim()}
          </label>
          <br />
          <label>
            <input type="radio" name="team" value="1" onChange={handleSelection}/>
            {teams.title.split("vs")[1].trim()}
          </label>
        </div>
        <div className="modal-footer">
          <button onClick={handleClose} className="cancel-button">Cancel</button>
          <button onClick={() => { handleBet(teams, selected) }} className="bet-button">Bet</button>
        </div>
      </div>
    </div>
  );
};

export default Modal;
