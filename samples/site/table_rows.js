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
