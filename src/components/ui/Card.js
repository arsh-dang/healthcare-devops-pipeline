import classes from './Card.module.css'

function Card(props) {
    return (<div className={classes.card} data-testid="card">{props.children}</div>);
}

export default Card;