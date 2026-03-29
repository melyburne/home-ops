document.addEventListener('DOMContentLoaded', () => {
    const countdownElement = document.getElementById('countdown');
    let timeLeft = 30; // 30 seconds

    const updateCountdown = () => {
        timeLeft -= 1;
        countdownElement.textContent = timeLeft;

        // When the timer hits zero, refresh the page
        if (timeLeft <= 0) {
            // A hard reload from the server to see if the Traefik route is back up
            window.location.reload(true);
        }
    };

    // Run the updateCountdown function every 1000 milliseconds (1 second)
    setInterval(updateCountdown, 1000);
});