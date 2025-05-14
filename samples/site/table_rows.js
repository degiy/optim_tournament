let lastSelectedTeam = null;

window.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('table').forEach(table => {
    const rows = table.querySelectorAll('tr.alt');
    rows.forEach((row, i) => {
      if (i % 2 === 1) {
        row.style.backgroundColor = '#e8e8e8';
      }
    });
  });

  document.querySelectorAll('table.score').forEach(table => {
    table.querySelectorAll('tr').forEach(row => {
      const cells = row.querySelectorAll('td');
      if (cells.length < 3) return;

      const extractScore = text => {
        const match = text.match(/ \((\d+)\)$/);
        return match ? parseInt(match[1]) : null;
      };

      const score1 = extractScore(cells[1].textContent);
      const score2 = extractScore(cells[2].textContent);

      if (score1 === null || score2 === null) return;

      if (score1 > score2) {
        cells[1].style.backgroundColor = '#d0f7c5';
        cells[2].style.backgroundColor = '#ffd6a8';
      } else if (score2 > score1) {
        cells[1].style.backgroundColor = '#ffd6a8';
        cells[2].style.backgroundColor = '#d0f7c5';
      } else {
        cells[1].style.backgroundColor = '#d0e8ff';
        cells[2].style.backgroundColor = '#d0e8ff';
      }
    });
  });

  const allTeamCells = document.querySelectorAll('td.team');

  const extractTeamName = text => {
    return text.replace(/\s*\(\d+\)\s*$/, '').trim();
  };

  allTeamCells.forEach(cell => {
    cell.addEventListener('click', () => {
      const teamName = extractTeamName(cell.textContent);

      if (teamName === lastSelectedTeam) {
        allTeamCells.forEach(c => c.classList.remove('selected-team'));
        lastSelectedTeam = null;
      } else {
        allTeamCells.forEach(c => c.classList.remove('selected-team'));
        allTeamCells.forEach(c => {
          if (extractTeamName(c.textContent) === teamName) {
            c.classList.add('selected-team');
          }
        });
        lastSelectedTeam = teamName;
      }
    });
  });
});

function checkHeaderAndRefresh() {
    var xhr = new XMLHttpRequest();
    xhr.open('HEAD', window.location.href, true);
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4 && xhr.status === 200) {
            var lastModified = xhr.getResponseHeader('Last-Modified');
            var headerDate = new Date(lastModified);

            // Get the last load date from local storage
            var lastLoadDate = localStorage.getItem('lastLoadDate');
            var lastLoadDateUTC = lastLoadDate ? new Date(lastLoadDate).getTime() : 0;

            // Convert header date to UTC
            var headerDateUTC = Date.UTC(
                headerDate.getUTCFullYear(),
                headerDate.getUTCMonth(),
                headerDate.getUTCDate(),
                headerDate.getUTCHours(),
                headerDate.getUTCMinutes(),
                headerDate.getUTCSeconds()
            );

            // Check if the header date is later than the last load date
            if (headerDateUTC > lastLoadDateUTC) {
                // Update the last load date in local storage
                localStorage.setItem('lastLoadDate', new Date().toISOString());
                location.reload();
            } else {
                var button = document.getElementById('refreshButton');
                if (button) {
                    button.innerText = 'a jour';
                    setTimeout(function() {
                        button.innerText = 'mettre a jour';
                    }, 2000);
                }
            }
        } else if (xhr.readyState === 4) {
            console.error('Failed to fetch the header. Status:', xhr.status);
        }
    };
    xhr.onerror = function() {
        console.error('An error occurred during the request.');
    };
    xhr.send(null);
}

// Store the initial load date when the page is loaded
window.onload = function() {
    localStorage.setItem('lastLoadDate', new Date().toISOString());
};

const MIN_SIZE = 12; // en px
const MAX_SIZE = 24;
const STEP = 2;
const KEY = "fontSizePx";

function applySize(size) {
  document.documentElement.style.fontSize = size + "px";
  localStorage.setItem(KEY, size);
}

function getCurrentSize() {
  return parseFloat(getComputedStyle(document.documentElement).fontSize);
}

function incSize() {
  let size = getCurrentSize();
  if (size + STEP <= MAX_SIZE) applySize(size + STEP);
}

function decSize() {
  let size = getCurrentSize();
  if (size - STEP >= MIN_SIZE) applySize(size - STEP);
}

// init depuis localStorage
const saved = parseFloat(localStorage.getItem(KEY));
if (!isNaN(saved)) applySize(saved);
