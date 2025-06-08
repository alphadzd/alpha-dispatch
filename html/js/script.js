
let currentCall = null;
let currentIndex = 0;
let totalCalls = 0;


const sounds = {
    high: new Audio('./sounds/dispatch_high_priority.wav'),
    medium: new Audio('./sounds/dispatch_medium_priority.wav'),
    low: new Audio('./sounds/dispatch_low_priority.wav')
};


window.addEventListener('message', function(event) {
    const data = event.data;

    switch (data.type) {
        case 'toggleDispatch':
            toggleDispatch(data.show);
            break;
        case 'updateCall':
            updateCallDisplay(data.call, data.currentIndex, data.totalCalls);
            break;
        case 'playSound':
            playAlertSound(data.sound, data.priority);
            
            if (data.isNewAlert) {
                const container = document.querySelector('.dispatch-container');
                if (container) {
                    const flashClass = `flash-${data.priority || 'low'}`;
                    container.classList.add(flashClass);
                    
                    setTimeout(() => {
                        container.classList.remove(flashClass);
                    }, 1000);
                }
            }
            break;
        case 'toggleMovable':
            toggleMovableMode();
            break;
        case 'openDemoDispatch':
            openDemoDispatch();
            break;
        case 'closeDemoDispatch':
            closeDemoDispatch();
            break;
        case 'setDispatchPosition':
            setDispatchPosition(data.x, data.y, data.width);
            break;
    }
});


function toggleDispatch(show) {
    const dispatchContainer = document.querySelector('.dispatch-container');
    const body = document.body;
    
    if (show) {

        dispatchContainer.style.position = 'absolute';
        
        dispatchContainer.style.display = 'flex';
        
        if (!dispatchContainer.style.left && !dispatchContainer.style.top) {
            dispatchContainer.style.right = '50px';
            dispatchContainer.style.top = '50%';
            dispatchContainer.style.transform = 'translateY(-50%)';
        }
        
        if (isMovable) {
            isMovable = false;
            dispatchContainer.classList.remove('movable');
            body.classList.remove('movable-mode');
            
            hideCursor();
            
            const indicator = document.querySelector('.movable-indicator');
            if (indicator) {
                indicator.remove();
            }
        } else {
            hideCursor();
            
            if (localStorage.getItem('movableHintShown') !== 'true') {
                setTimeout(() => {
                    showNotification('TIP: Double-click the header or right-click anywhere to enter movable mode', 'info', 5000);
                    localStorage.setItem('movableHintShown', 'true');
                }, 2000);
            }
        }
    } else {
        dispatchContainer.style.display = 'none';
        
        const allElements = document.querySelectorAll('*');
        allElements.forEach(el => {
            el.style.cursor = '';
        });
        document.documentElement.style.cursor = '';
        document.body.style.cursor = '';
    }
}


function updateCallDisplay(call, index, total) {
    currentCall = call;
    currentIndex = index;
    totalCalls = total;

    document.getElementById('callCounter').textContent = `${index}/${total}`;

    if (!call) {
        document.getElementById('callCode').textContent = 'No Calls';
        document.getElementById('callTitle').textContent = 'No active emergency calls';
        document.getElementById('locationText').textContent = 'N/A';
        document.getElementById('timeAgo').textContent = '';
        
        document.getElementById('prevBtn').disabled = true;
        document.getElementById('nextBtn').disabled = true;
        document.getElementById('respondBtn').disabled = true;
        return;
    }

    document.getElementById('prevBtn').disabled = index <= 1;
    document.getElementById('nextBtn').disabled = index >= total;
    document.getElementById('respondBtn').disabled = false;

    document.getElementById('callCode').textContent = call.code;
    
    let titleText = call.title;
    
    if (call.vehicle && (call.title.includes('Car Jacking') || call.title.includes('Car Rob'))) {
        const vehicle = call.vehicle;
        titleText += ` - ${vehicle.color} ${vehicle.model}`;
        
        if (vehicle.plate) {
            titleText += ` (${vehicle.plate})`;
        }
    }
    
    if (call.weapon && call.title.includes('Shots Fired')) {
        titleText += ` - ${call.weapon}`;
    }
    
    if (call.title.includes('911 Emergency Call') && call.weapon) {
        titleText += ` - "${call.weapon}"`;
    }
    
    document.getElementById('callTitle').textContent = titleText;
    
    document.getElementById('locationText').textContent = call.location;
    
    let timeText = call.timeAgo;
    
    if (call.distance) {
        timeText += ` - ${call.distance}`;
    }
    
    if (call.suspect) {
        if (call.title.includes('911 Emergency Call')) {
            timeText += `<br>Caller: ${call.suspect}`;
        }
        else if (call.title.includes('PANIC BUTTON') || call.title.includes('REQUESTING PICKUP')) {
            timeText += `<br>${call.suspect}`;
        }
    }
    
    document.getElementById('timeAgo').innerHTML = timeText;

    const respondBtn = document.getElementById('respondBtn');
    if (call.responded) {
        respondBtn.innerHTML = '<i class="fas fa-check"></i> Responded';
        respondBtn.classList.add('responded');
    } else {
        respondBtn.innerHTML = '<i class="fa-solid fa-g"></i>';
        respondBtn.classList.remove('responded');
    }

    updatePriorityStyle(call.priority);
}


function updatePriorityStyle(priority) {
    const container = document.querySelector('.dispatch-container');
    const warningIcon = document.querySelector('.warning-icon');
    const priorityText = document.querySelector('.priority-text');
    
    container.classList.remove('priority-high', 'priority-medium', 'priority-low');
    
    if (warningIcon) {
        warningIcon.classList.remove('high-priority', 'medium-priority', 'low-priority');
    }
    
    if (priority === 'high') {
        container.classList.add('priority-high');
        if (warningIcon) warningIcon.classList.add('high-priority');
        if (priorityText) priorityText.textContent = 'HIGH PRIORITY';
    } else if (priority === 'medium') {
        container.classList.add('priority-medium');
        if (warningIcon) warningIcon.classList.add('medium-priority');
        if (priorityText) priorityText.textContent = 'MEDIUM PRIORITY';
    } else {
        container.classList.add('priority-low');
        if (warningIcon) warningIcon.classList.add('low-priority');
        if (priorityText) priorityText.textContent = 'LOW PRIORITY';
    }
}


function playAlertSound(sound, priority) {
    if (sounds[priority]) {
        sounds[priority].currentTime = 0;
        sounds[priority].volume = 0.5;
        sounds[priority].play().catch(console.error);
    } else {
        const audio = new Audio(`sounds/dispatch_${priority}_priority.wav`);
        audio.volume = 0.5;
        audio.play().catch(console.error);
    }
    
    const alertDot = document.querySelector('.alert-dot');
    if (alertDot) {
        alertDot.classList.add('flashing');
        
        setTimeout(() => {
            alertDot.classList.remove('flashing');
        }, 3000);
    }
}


function previousCall() {
    $.post('https://alpha-dispatch/previousCall', {}, function(data) {
        if (data === 'ok') {
            }
    });
}

function nextCall() {
    $.post('https://alpha-dispatch/nextCall', {}, function(data) {
        if (data === 'ok') {
        }
    });
}

function respondToCall() {
    if (!currentCall || currentCall.responded) return;
    
    const respondBtn = document.getElementById('respondBtn');
    if (respondBtn) {
        respondBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i>';
    }
    
    if (!currentCall.coords) {
        console.error("No coordinates available for this call");
        if (respondBtn) {
            respondBtn.innerHTML = '<i class="fa-solid fa-g"></i>';
        }
        return;
    }
    
    $.post('https://alpha-dispatch/respondToCall', {}, function(data) {
        if (data === 'ok') {
            currentCall.responded = true;
            updateCallDisplay(currentCall, currentIndex, totalCalls);
            
            const confirmSound = new Audio('data:audio/wav;base64,UklGRigAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQQAAAAAAA==');
            confirmSound.volume = 0.3;
            confirmSound.play().catch(console.error);
            
            const container = document.querySelector('.dispatch-container');
            const flash = document.createElement('div');
            flash.className = 'response-flash';
            container.appendChild(flash);
            
            setTimeout(() => {
                container.removeChild(flash);
            }, 500);
        } else {
            if (respondBtn) {
                respondBtn.innerHTML = '<i class="fa-solid fa-g"></i>';
            }
        }
    });
}

function goToLatestCall() {
    if (totalCalls > 0) {
        if (currentIndex !== 1) {
            $.post('https://alpha-dispatch/goToCall', { index: 1 }, function(data) {
                if (data === 'ok') {
                    currentIndex = 1;
                    if (currentCalls && currentCalls.length > 0) {
                        updateCallDisplay(currentCalls[0], 1, totalCalls);
                    }
                }
            });
        }
        return true; 
    }
    return false; 
}


let isDragging = false;
let isMovable = false;
let isResizing = false;
let offsetX, offsetY;
let startWidth, startX;

function showCursor() {
    const allElements = document.querySelectorAll('*');
    allElements.forEach(el => {
        el.style.setProperty('cursor', 'default', 'important');
    });
    
    document.documentElement.style.setProperty('cursor', 'default', 'important');
    document.body.style.setProperty('cursor', 'default', 'important');
    
    const container = document.querySelector('.dispatch-container');
    if (container) {
        container.style.setProperty('cursor', 'move', 'important');
    }
    
    const buttons = document.querySelectorAll('.btn, button, .move-toggle');
    buttons.forEach(btn => {
        btn.style.setProperty('cursor', 'pointer', 'important');
    });
}

function hideCursor() {
    const allElements = document.querySelectorAll('*');
    allElements.forEach(el => {
        el.style.setProperty('cursor', 'none', 'important');
    });
    
    document.documentElement.style.setProperty('cursor', 'none', 'important');
    document.body.style.setProperty('cursor', 'none', 'important');
}
document.addEventListener('keydown', function(event) {
    const dispatchContainer = document.querySelector('.dispatch-container');
    if (dispatchContainer.style.display !== 'flex') return;

    switch (event.key.toLowerCase()) {
        case 'escape':
            if (isMovable) {
                toggleMovableMode();
                return;
            }
            
            if (isDemoMode) {
                return;
            }
            
            $.post('https://alpha-dispatch/closeDispatch', {
                isMovableMode: isMovable || isDemoMode
            }, function(data) {
                if (data === 'ok') {
                    toggleDispatch(false);
                }
            });
            break;
        case 'm':
            if (event.ctrlKey || event.altKey) {
                toggleMovableMode();
                event.preventDefault();
            }
            break;
        case 'g':
            if (totalCalls > 0) {
                const wasOnLatestCall = (currentIndex === 1);
                const hasActiveCalls = goToLatestCall();
                
                setTimeout(() => {
                    if (currentCall && !currentCall.responded) {
                        respondToCall();
                    } else if (wasOnLatestCall && currentCall && currentCall.responded) {
                        const respondBtn = document.getElementById('respondBtn');
                        if (respondBtn) {
                            respondBtn.classList.add('flash-button');
                            setTimeout(() => {
                                respondBtn.classList.remove('flash-button');
                            }, 500);
                        }
                    }
                }, 100);
            }
            break;
        case 'arrowleft':
            if (currentIndex > 1) {
                previousCall();
            }
            break;
        case 'arrowright':
            if (currentIndex < totalCalls) {
                nextCall();
            }
            break;
    }
});

let isDemoMode = false;

function toggleMovableMode() {
    const dispatchContainer = document.querySelector('.dispatch-container');
    const body = document.body;
    const moveToggle = document.getElementById('moveToggle');
    
    isMovable = !isMovable;
    isDragging = false;
    isResizing = false;
    
    if (isMovable) {
        dispatchContainer.classList.add('movable');
        body.classList.add('movable-mode');
        
        dispatchContainer.style.position = 'absolute';
        
        dispatchContainer.style.transform = 'none';
        dispatchContainer.style.right = 'auto';
        
        if (moveToggle) {
            moveToggle.classList.add('active');
        }
        
        showCursor();
        
        if (!document.querySelector('.movable-indicator')) {
            const indicator = document.createElement('div');
            indicator.className = 'movable-indicator';
            indicator.innerHTML = '<i class="fas fa-arrows-alt"></i>';
            dispatchContainer.appendChild(indicator);
        }
        
        if (!dispatchContainer.style.left) {
            const rect = dispatchContainer.getBoundingClientRect();
            const centerX = (window.innerWidth - rect.width) / 2;
            const centerY = (window.innerHeight - rect.height) / 2;
            
            dispatchContainer.style.left = `${centerX}px`;
            dispatchContainer.style.top = `${centerY}px`;
        }
        
        if (!document.querySelector('.resize-handle')) {
            const resizeHandle = document.createElement('div');
            resizeHandle.className = 'resize-handle';
            resizeHandle.innerHTML = '<i class="fas fa-arrows-alt-h"></i>';
            dispatchContainer.appendChild(resizeHandle);
            
            initResizeFunctionality();
        }
        
        if (!document.querySelector('.controls-row')) {
            const controlsRow = document.createElement('div');
            controlsRow.className = 'controls-row';
            controlsRow.style.display = 'flex';
            controlsRow.style.justifyContent = 'space-between';
            controlsRow.style.marginTop = '10px';
            controlsRow.style.padding = '0 10px 10px 10px';
            
            const sizeControls = document.createElement('div');
            sizeControls.className = 'size-controls-inline';
            sizeControls.style.display = 'flex';
            sizeControls.style.gap = '5px';
            
            const sizeLabel = document.createElement('div');
            sizeLabel.className = 'size-label';
            sizeLabel.innerHTML = 'Size:';
            sizeLabel.style.color = 'white';
            sizeLabel.style.fontSize = '12px';  
            sizeLabel.style.marginRight = '8px';
            sizeLabel.style.display = 'flex';
            sizeLabel.style.alignItems = 'center';
            sizeLabel.style.fontWeight = 'bold';
            sizeControls.appendChild(sizeLabel);
            
            const smallBtn = document.createElement('button');
            smallBtn.className = 'size-btn small-btn btn';
            smallBtn.innerHTML = 'S';
            smallBtn.style.backgroundColor = '#3498db';
            smallBtn.style.color = 'white';
            smallBtn.style.border = 'none';
            smallBtn.style.width = '30px';
            smallBtn.style.height = '30px';
            smallBtn.style.borderRadius = '4px';
            smallBtn.style.cursor = 'pointer';
            smallBtn.addEventListener('click', () => resizeDispatch(220));
            
            const mediumBtn = document.createElement('button');
            mediumBtn.className = 'size-btn medium-btn btn';
            mediumBtn.innerHTML = 'M';
            mediumBtn.style.backgroundColor = '#27ae60';
            mediumBtn.style.color = 'white';
            mediumBtn.style.border = 'none';
            mediumBtn.style.width = '30px';
            mediumBtn.style.height = '30px';
            mediumBtn.style.borderRadius = '4px';
            mediumBtn.style.cursor = 'pointer';
            mediumBtn.addEventListener('click', () => resizeDispatch(250));
            
            const largeBtn = document.createElement('button');
            largeBtn.className = 'size-btn large-btn btn';
            largeBtn.innerHTML = 'L';
            largeBtn.style.backgroundColor = '#e74c3c';
            largeBtn.style.color = 'white';
            largeBtn.style.border = 'none';
            largeBtn.style.width = '30px';
            largeBtn.style.height = '30px';
            largeBtn.style.borderRadius = '4px';
            largeBtn.style.cursor = 'pointer';
            largeBtn.addEventListener('click', () => resizeDispatch(280));
            
            sizeControls.appendChild(smallBtn);
            sizeControls.appendChild(mediumBtn);
            sizeControls.appendChild(largeBtn);
            
            const saveBtn = document.createElement('button');
            saveBtn.className = 'save-btn btn';
            saveBtn.innerHTML = 'Save';
            saveBtn.style.backgroundColor = '#2ecc71';
            saveBtn.style.color = 'white';
            saveBtn.style.border = 'none';
            saveBtn.style.padding = '5px 10px';
            saveBtn.style.borderRadius = '4px';
            saveBtn.style.cursor = 'pointer';
            saveBtn.style.marginLeft = '10px';
            saveBtn.addEventListener('click', saveDispatchPosition);
            
            sizeControls.appendChild(saveBtn);
            
            controlsRow.appendChild(sizeControls);
            dispatchContainer.appendChild(controlsRow);
        }
        
        showNotification('Dispatch window is now movable. Drag to move, use S/M/L buttons to resize, or drag the right edge to adjust width.');
    } else {
        dispatchContainer.classList.remove('movable');
        dispatchContainer.classList.remove('dragging');
        body.classList.remove('movable-mode');
        
        if (moveToggle) {
            moveToggle.classList.remove('active');
        }
        
        const resizeHandle = document.querySelector('.resize-handle');
        if (resizeHandle) {
            resizeHandle.remove();
        }
        
        const controlsRow = document.querySelector('.controls-row');
        if (controlsRow) {
            controlsRow.remove();
        }
        
        const movableIndicator = document.querySelector('.movable-indicator');
        if (movableIndicator) {
            movableIndicator.remove();
        }
        
        hideCursor();
        
        showNotification('Dispatch window is now fixed.');
    }
    
    if (moveToggle) {
        moveToggle.style.setProperty('cursor', 'pointer', 'important');
    }
}

function openDemoDispatch() {
    isDemoMode = true;
    const dispatchContainer = document.querySelector('.dispatch-container');
    const body = document.body;
    
    dispatchContainer.style.display = 'flex';
    
    dispatchContainer.classList.add('demo-mode');
    body.classList.add('movable-mode');
    
    dispatchContainer.classList.add('movable');
    isMovable = true;
    showCursor();
    
    if (!document.querySelector('.priority-controls')) {
        const priorityControls = document.createElement('div');
        priorityControls.className = 'priority-controls';
        
        const priorityLabel = document.createElement('div');
        priorityLabel.className = 'priority-label';
        priorityLabel.innerHTML = 'Priority:';
        priorityControls.appendChild(priorityLabel);
        
        const highBtn = document.createElement('button');
        highBtn.className = 'priority-btn high-btn';
        highBtn.innerHTML = 'HIGH';
        highBtn.addEventListener('click', () => updatePriority('high'));
        
        const mediumBtn = document.createElement('button');
        mediumBtn.className = 'priority-btn medium-btn';
        mediumBtn.innerHTML = 'MEDIUM';
        mediumBtn.addEventListener('click', () => updatePriority('medium'));
        
        const lowBtn = document.createElement('button');
        lowBtn.className = 'priority-btn low-btn';
        lowBtn.innerHTML = 'LOW';
        lowBtn.addEventListener('click', () => updatePriority('low'));
        
        priorityControls.appendChild(highBtn);
        priorityControls.appendChild(mediumBtn);
        priorityControls.appendChild(lowBtn);
        
        document.body.appendChild(priorityControls);
    }
    
        if (!document.querySelector('.close-demo-btn')) {
        const closeBtn = document.createElement('button');
        closeBtn.className = 'close-demo-btn';
        closeBtn.innerHTML = '<i class="fas fa-times"></i>';
        closeBtn.addEventListener('click', cancelDemoMode);
        
        document.body.appendChild(closeBtn);
    }
    
    if (!document.querySelector('.move-instructions')) {
        const instructions = document.createElement('div');
        instructions.className = 'move-instructions';
        
        const title = document.createElement('div');
        title.className = 'title';
        title.textContent = 'DISPATCH POSITION SETUP';
        
        const subtitle1 = document.createElement('div');
        subtitle1.className = 'subtitle';
        subtitle1.textContent = 'Click and drag the dispatch window to your preferred position';
        
        const subtitle2 = document.createElement('div');
        subtitle2.className = 'subtitle';
        subtitle2.textContent = 'Use S, M, L buttons to adjust the size';
        
        instructions.appendChild(title);
        instructions.appendChild(subtitle1);
        instructions.appendChild(subtitle2);
        
        document.body.appendChild(instructions);
    }
    
    const rect = dispatchContainer.getBoundingClientRect();
    const centerX = (window.innerWidth - rect.width) / 2;
    const centerY = (window.innerHeight - rect.height) / 2;
    
    dispatchContainer.style.left = `${centerX}px`;
    dispatchContainer.style.top = `${centerY}px`;
    showNotification('Dispatch position setup mode activated. Drag to position and use S/M/L buttons to resize.', 'info', 5000);
}

function closeDemoDispatch() {
    isDemoMode = false;
    isMovable = false;
    const dispatchContainer = document.querySelector('.dispatch-container');
    
    dispatchContainer.style.display = 'none';
    
    dispatchContainer.classList.remove('demo-mode');
    dispatchContainer.classList.remove('movable');
    document.body.classList.remove('movable-mode');
    
    const sizeControls = document.querySelector('.size-controls');
    if (sizeControls) {
        sizeControls.remove();
    }
    
    const priorityControls = document.querySelector('.priority-controls');
    if (priorityControls) {
        priorityControls.remove();
    }
    
    const closeBtn = document.querySelector('.close-demo-btn');
    if (closeBtn) {
        closeBtn.remove();
    }
    
    const instructions = document.querySelector('.move-instructions');
    if (instructions) {
        instructions.remove();
    }
    
    showNotification('Dispatch position setup canceled', 'error', 3000);
    $.post('https://alpha-dispatch/resetNuiFocus', {});
}

function cancelDemoMode() {
    closeDemoDispatch();
    
    $.post('https://alpha-dispatch/cancelDemoMode', {}, function(data) {
        console.log('Demo mode canceled');
    });
}
function updatePriority(priority) {
    const priorityIndicator = document.querySelector('.priority-indicator');
    const priorityText = document.querySelector('.priority-text');
    const dispatchContainer = document.querySelector('.dispatch-container');
    
    if (!priorityIndicator || !priorityText || !dispatchContainer) return;
    
    dispatchContainer.classList.remove('priority-high', 'priority-medium', 'priority-low');
    if (priority === 'high') {
        priorityText.textContent = 'HIGH';
        dispatchContainer.classList.add('priority-high');
    } else if (priority === 'medium') {
        priorityText.textContent = 'MEDIUM';
        dispatchContainer.classList.add('priority-medium');
    } else if (priority === 'low') {
        priorityText.textContent = 'LOW';
        dispatchContainer.classList.add('priority-low');
    }
    
    let notificationText = `Priority changed to ${priority.toUpperCase()}`;
    showNotification(notificationText, 'info', 2000);
}

function saveDispatchPosition() {
    const dispatchContainer = document.querySelector('.dispatch-container');
    const rect = dispatchContainer.getBoundingClientRect();
    
    const width = dispatchContainer.style.width ? parseInt(dispatchContainer.style.width) : 250;
    
    isMovable = false;
    dispatchContainer.classList.remove('movable');
    document.body.classList.remove('movable-mode');
    const resizeHandle = document.querySelector('.resize-handle');
    if (resizeHandle) {
        resizeHandle.remove();
    }
    
    const controlsRow = document.querySelector('.controls-row');
    if (controlsRow) {
        controlsRow.remove();
    }
    
    const movableIndicator = document.querySelector('.movable-indicator');
    if (movableIndicator) {
        movableIndicator.remove();
    }
    
    $.post('https://alpha-dispatch/saveDispatchPosition', {
        x: rect.left,
        y: rect.top,
        width: width
    }, function(data) {
        if (data === 'ok') {
            showNotification('Dispatch position saved', 'info', 2000);
            
            $.post('https://alpha-dispatch/closeDispatch', {
                isMovableMode: false
            }, function(response) {
                if (response === 'ok') {
                    toggleDispatch(false);
                }
            });
        }
    });
}

function cancelDemoMode() {
    $.post('https://alpha-dispatch/cancelDemoMode', {});
}
function setDispatchPosition(x, y, width) {
    const dispatchContainer = document.querySelector('.dispatch-container');
    
    if (dispatchContainer && x !== undefined && y !== undefined) {
        dispatchContainer.style.position = 'absolute';
        
        dispatchContainer.style.left = `${x}px`;
        dispatchContainer.style.top = `${y}px`;
        
        if (width && width >= 200) {
            dispatchContainer.style.width = `${width}px`;
        }
        dispatchContainer.style.transform = 'none';
        dispatchContainer.style.right = 'auto';
        
        const rect = dispatchContainer.getBoundingClientRect();
        const screenWidth = window.innerWidth || document.documentElement.clientWidth;
        const screenHeight = window.innerHeight || document.documentElement.clientHeight;
        if (rect.right > screenWidth) {
            dispatchContainer.style.left = `${screenWidth - rect.width}px`;
        }
        if (rect.bottom > screenHeight) {
            dispatchContainer.style.top = `${screenHeight - rect.height}px`;
        }
        if (rect.left < 0) {
            dispatchContainer.style.left = '0px';
        }
        if (rect.top < 0) {
            dispatchContainer.style.top = '0px';
        }
    }
}

function showNotification(message, type = 'info', duration = 3000) {
    const existingNotification = document.querySelector('.custom-notification');
    if (existingNotification) {
        existingNotification.remove();
    }
    
    const notification = document.createElement('div');
    notification.className = `custom-notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
        notification.classList.add('show');
    }, 10);
    
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            notification.remove();
        }, 300);
    }, duration);
    if (!isDemoMode) {
        $.post('https://alpha-dispatch/showNotification', {
            message: message
        });
    }
}


function GetParentResourceName() {
    try {
        return window.GetParentResourceName();
    } catch (e) {
        console.error('Failed to get resource name:', e);
        return 'alpha-dispatch';
    }
}


document.addEventListener('DOMContentLoaded', function() {
    const dispatchContainer = document.querySelector('.dispatch-container');
    dispatchContainer.style.display = 'none';
    
    document.getElementById('prevBtn').addEventListener('click', previousCall);
    document.getElementById('nextBtn').addEventListener('click', nextCall);
    document.getElementById('respondBtn').addEventListener('click', respondToCall);
    
    const closeBtn = document.getElementById('closeDispatch');
    if (closeBtn) {
        closeBtn.addEventListener('click', function() {
            if (isMovable) {
                saveDispatchPosition();
            } else {
                $.post('https://alpha-dispatch/closeDispatch', {
                    isMovableMode: false
                }, function(data) {
                    if (data === 'ok') {
                        toggleDispatch(false);
                    }
                });
            }
        });
    }
    
    initDragFunctionality();
    
    const moveToggle = document.getElementById('moveToggle');
    if (moveToggle) {
        moveToggle.addEventListener('click', function(e) {
            toggleMovableMode();
            e.stopPropagation();
        });
        
        moveToggle.style.setProperty('cursor', 'pointer', 'important');
    }
    
    Object.values(sounds).forEach(audio => {
        audio.volume = 0.7;
        audio.addEventListener('error', (e) => {
            console.error('Audio loading error:', e);
        });
        audio.load();
    });
    
    const dispatchHeader = document.querySelector('.dispatch-header');
    if (dispatchHeader) {
        dispatchHeader.addEventListener('dblclick', function(e) {
            toggleMovableMode();
            e.stopPropagation();
        });
    }
    
    dispatchContainer.addEventListener('contextmenu', function(e) {
        e.preventDefault();
        toggleMovableMode();
    });
    hideCursor();
});

function initDragFunctionality() {
    const dispatchContainer = document.querySelector('.dispatch-container');
    
    dispatchContainer.addEventListener('mousedown', function(e) {
        if (!isMovable) return;
        
        if (isResizing) return;
        
        const header = dispatchContainer.querySelector('.dispatch-header');
        if (header && header.contains(e.target) || e.target === header || e.target === dispatchContainer) {
            e.preventDefault();
            isDragging = true;
            
            const rect = dispatchContainer.getBoundingClientRect();
            offsetX = e.clientX - rect.left;
            offsetY = e.clientY - rect.top;
            
            dispatchContainer.classList.add('dragging');
            
            document.documentElement.style.cursor = 'move';
            document.body.style.cursor = 'move';
        }
    });
    
    document.addEventListener('mousemove', function(e) {
        if (isResizing && isMovable) {
            e.preventDefault();
            const newWidth = startWidth + (e.clientX - startX);
            
            const limitedWidth = Math.max(200, Math.min(newWidth, 320));
            
            dispatchContainer.style.width = `${limitedWidth}px`;
            return;
        }
        
        if (isDragging && isMovable) {
            e.preventDefault();
            
            const x = e.clientX - offsetX;
            const y = e.clientY - offsetY;
            
            const maxX = window.innerWidth - dispatchContainer.offsetWidth;
            const maxY = window.innerHeight - dispatchContainer.offsetHeight;
            
            const boundedX = Math.max(0, Math.min(x, maxX));
            const boundedY = Math.max(0, Math.min(y, maxY));
            
            dispatchContainer.style.left = `${boundedX}px`;
            dispatchContainer.style.top = `${boundedY}px`;
            
            dispatchContainer.style.transform = 'none';
            dispatchContainer.style.right = 'auto';
        }
    });
    
    document.addEventListener('mouseup', function(e) {
        if (isDragging || isResizing) {
            e.preventDefault();
            isDragging = false;
            isResizing = false;
            dispatchContainer.classList.remove('dragging');
            dispatchContainer.classList.remove('resizing');
                        if (isMovable) {
                document.documentElement.style.cursor = 'default';
                document.body.style.cursor = 'default';
                dispatchContainer.style.cursor = 'move';
            } else {
                hideCursor(); 
            }
        }
    });
    
    document.addEventListener('mouseleave', function() {
        if (isDragging || isResizing) {
            isDragging = false;
            isResizing = false;
            dispatchContainer.classList.remove('dragging');
            dispatchContainer.classList.remove('resizing');
            
            if (isMovable) {
                document.documentElement.style.cursor = 'default';
                document.body.style.cursor = 'default';
                dispatchContainer.style.cursor = 'move';
            } else {
                hideCursor(); 
            }
        }
    });
    
    const buttons = dispatchContainer.querySelectorAll('.btn, button, .move-toggle');
    buttons.forEach(button => {
        button.addEventListener('mousedown', function(e) {
            e.stopPropagation();
        });
    });
    
    dispatchContainer.addEventListener('selectstart', function(e) {
        if (isMovable) {
            e.preventDefault();
        }
    });
}

function initResizeFunctionality() {
    const dispatchContainer = document.querySelector('.dispatch-container');
    const resizeHandle = document.querySelector('.resize-handle');
    
    if (!resizeHandle) return;
    
    resizeHandle.addEventListener('mousedown', function(e) {
        if (!isMovable) return;
        
        e.preventDefault();
        e.stopPropagation(); 
        
        isResizing = true;
        
        startWidth = dispatchContainer.offsetWidth;
        startX = e.clientX;
        
        dispatchContainer.classList.add('resizing');
        
        document.documentElement.style.cursor = 'ew-resize';
        document.body.style.cursor = 'ew-resize';
    });
}

function resizeDispatch(width) {
    if (!isMovable && !isDemoMode) return;

    const dispatchContainer = document.querySelector('.dispatch-container');

    dispatchContainer.style.transition = 'width 0.3s ease, height 0.3s ease';
    dispatchContainer.style.width = `${width}px`;
    
    let height;
    if (width === 220) {
        height = 280;
    } else if (width === 250) {
        height = 300;
    } else if (width === 280) {
        height = 320;
    } else {
        height = width * 1.1;
    }
    
    dispatchContainer.style.minHeight = `${height}px`;
    
    setTimeout(() => {
        dispatchContainer.style.transition = '';
    }, 300);
    
   
    const sizeButtons = document.querySelectorAll('.size-btn');
    sizeButtons.forEach(btn => {
        btn.classList.remove('active');
        btn.style.transform = '';
        btn.style.boxShadow = '';
    });
    
    let activeButton;
    let sizeLabel = '';
    
    if (width === 220) {
        activeButton = document.querySelector('.small-btn');
        sizeLabel = 'Small';
    } else if (width === 250) {
        activeButton = document.querySelector('.medium-btn');
        sizeLabel = 'Medium';
    } else if (width === 280) {
        activeButton = document.querySelector('.large-btn');
        sizeLabel = 'Large';
    }
    
    if (activeButton) {
        activeButton.classList.add('active');
        activeButton.style.transform = 'translateY(-2px)';
        activeButton.style.boxShadow = '0 4px 8px rgba(0, 0, 0, 0.3)';
        
        showNotification(`Dispatch size changed to ${sizeLabel}`, 'info', 2000);
    }
}
function cancelDemoMode() {
    $.post('https://alpha-dispatch/cancelDemoMode', {});
}