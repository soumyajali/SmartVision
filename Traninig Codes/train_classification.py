import os
import torch
import torch.nn as nn
import torch.optim as optim
from torchvision import datasets, transforms, models
from torch.utils.data import DataLoader
from PIL import Image
import numpy as np

def create_dummy_dataset(base_path, classes, num_images_per_class=5):
    """Creates a dummy dataset with random images for testing the training loop."""
    print(f"Creating dummy dataset in {base_path}...")
    for split in ['train', 'test']:
        split_path = os.path.join(base_path, split)
        os.makedirs(split_path, exist_ok=True)
        
        for cls_name in classes:
            cls_path = os.path.join(split_path, cls_name)
            os.makedirs(cls_path, exist_ok=True)
            
            for i in range(num_images_per_class):
                # Generate a random 224x224 RGB image
                random_image = np.random.randint(0, 256, (224, 224, 3), dtype=np.uint8)
                img = Image.fromarray(random_image)
                img.save(os.path.join(cls_path, f"dummy_{i}.jpg"))

def main():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print("Using Device:", device)

    classes = [
        'Chair', 'bottle', 'Cat', 'Cup', 'Bench', 'Horse', 'Person', 'bed', 'Truck', 'Airplane',
        'Cycle', 'Bird', 'bike', 'bus', 'potted plant', 'Pizza', 'Stop Signal', 'Bowl',
        'Traffic Signal', 'couch', 'elephant', 'Cake', 'dog', 'cow', 'Car'
    ]
    num_classes = len(classes)

    dataset_dir = "dummy_classification_dataset"
    create_dummy_dataset(dataset_dir, classes)

    train_path = os.path.join(dataset_dir, "train")
    
    train_tf = transforms.Compose([
        transforms.Resize((224, 224)),
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.485, 0.456, 0.406], std=[0.229, 0.224, 0.225])
    ])

    train_ds = datasets.ImageFolder(train_path, transform=train_tf)
    train_loader = DataLoader(train_ds, batch_size=8, shuffle=True)

    print("Loading MobileNetV2...")
    model = models.mobilenet_v2(weights=models.MobileNet_V2_Weights.DEFAULT)

    # Freeze base feature layers
    for param in model.features.parameters():
        param.requires_grad = False

    # Custom classifier for 25 classes
    model.classifier = nn.Sequential(
        nn.Dropout(0.2),
        nn.Linear(model.last_channel, num_classes)
    )
    
    model = model.to(device)
    
    criterion = nn.CrossEntropyLoss()
    optimizer = optim.Adam(model.classifier.parameters(), lr=0.001)

    epochs = 2
    print(f"Starting training for {epochs} epochs on dummy dataset...")
    
    for epoch in range(epochs):
        model.train()
        running_loss = 0.0
        
        for images, labels in train_loader:
            images, labels = images.to(device), labels.to(device)

            optimizer.zero_grad()
            outputs = model(images)
            loss = criterion(outputs, labels)
            loss.backward()
            optimizer.step()

            running_loss += loss.item()
            
        print(f"Epoch {epoch+1}/{epochs} | Loss: {running_loss:.3f}")

    # Save model
    save_path = "MobileNET_best_dummy.pth"
    torch.save(model.state_dict(), save_path)
    print(f"Training complete! Model saved to {save_path}")

if __name__ == '__main__':
    main()
