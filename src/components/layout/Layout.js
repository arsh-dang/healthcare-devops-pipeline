import classes from './Layout.module.css';
import PropTypes from 'prop-types';
import MainNavigation from './MainNavigation';

function Layout(props) {
    return (
        <div>
            <MainNavigation />
            <main className={classes.main}>
                {props.children}
            </main>
        </div>
    );
}

Layout.propTypes = {
    children: PropTypes.node.isRequired
};

export default Layout;