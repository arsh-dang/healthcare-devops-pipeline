import classes from './Card.module.css';
import PropTypes from 'prop-types';

function Card(props) {
    return (<div className={classes.card} data-testid="card">{props.children}</div>);
}

Card.propTypes = {
    children: PropTypes.node.isRequired
};

export default Card;