// Note management functions
let activeNotes = new Set();

function toggleNote(noteId) {
    if (activeNotes.has(noteId)) {
        hideNote(noteId);
    } else {
        showNote(noteId);
    }
}

function showNote(noteId) {
    const noteElement = document.getElementById(noteId);
    const highlight = document.querySelector(\`.highlight[data-note="\${noteId}"]\`);
    
    if (noteElement && highlight) {
        activeNotes.add(noteId);
        noteElement.classList.remove('hidden');
        highlight.classList.add('active');
        
        setTimeout(() => {
            noteElement.classList.add('active');
        }, 10);
        
        positionNotes();
    }
}

function hideNote(noteId) {
    const noteElement = document.getElementById(noteId);
    const highlight = document.querySelector(\`.highlight[data-note="\${noteId}"]\`);
    
    if (noteElement && highlight) {
        activeNotes.delete(noteId);
        noteElement.classList.remove('active');
        highlight.classList.remove('active');
        
        setTimeout(() => {
            noteElement.classList.add('hidden');
        }, 300);
        
        positionNotes();
    }
}

function positionNotes() {
    const sideNotesContainer = document.getElementById('side-notes-container');
    const mainContent = document.querySelector('.main-content');
    
    sideNotesContainer.style.height = '';
    const activeNoteElements = Array.from(activeNotes).map(id => 
        document.getElementById(id)
    ).filter(el => el !== null);
    
    sideNotesContainer.style.height = `${mainContent.offsetHeight}px`;
    
    activeNoteElements.forEach(note => {
        note.style.top = '';
    });
    
    activeNoteElements.forEach(noteElement => {
        const noteId = noteElement.id;
        const highlight = document.querySelector(`.highlight[data-note="${noteId}"]`);
        
        if (highlight) {
            const highlightRect = highlight.getBoundingClientRect();
            const mainContentRect = mainContent.getBoundingClientRect();
            const topPosition = highlightRect.top - mainContentRect.top;
            
            noteElement.style.top = `${topPosition}px`;
            resolveOverlaps(noteElement, topPosition, activeNoteElements);
        }
    });
}

function resolveOverlaps(currentNote, currentTop, allNotes) {
    const noteHeight = currentNote.offsetHeight;
    const currentBottom = currentTop + noteHeight;
    const containerHeight = document.getElementById('side-notes-container').offsetHeight;
    
    allNotes.forEach(otherNote => {
        if (otherNote !== currentNote && otherNote.style.top) {
            const otherTop = parseInt(otherNote.style.top);
            const otherBottom = otherTop + otherNote.offsetHeight;
            
            if ((currentTop >= otherTop && currentTop <= otherBottom) ||
                (currentBottom >= otherTop && currentBottom <= otherBottom) ||
                (currentTop <= otherTop && currentBottom >= otherBottom)) {
                
                let newTop = otherBottom + 10;
                
                if (newTop + noteHeight > containerHeight) {
                    newTop = otherTop - noteHeight - 10;
                }
                
                if (newTop < 0) {
                    newTop = containerHeight - noteHeight - 10;
                }
                
                currentNote.style.top = `${newTop}px`;
                resolveOverlaps(currentNote, newTop, allNotes);
            }
        }
    });
}

// Add generated notes JavaScript here
// GENERATED_JAVASCRIPT

// Handle window resize
window.addEventListener('resize', function() {
    if (activeNotes.size > 0) {
        positionNotes();
    }
});

