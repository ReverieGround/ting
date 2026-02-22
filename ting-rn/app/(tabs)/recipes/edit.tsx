import { useState, useCallback, useEffect, useRef } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
  Image,
  Alert,
  ActivityIndicator,
  Dimensions,
  FlatList,
  Pressable,
} from 'react-native';
import { useLocalSearchParams, router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import * as ImagePicker from 'expo-image-picker';
import {
  ExpoSpeechRecognitionModule,
  useSpeechRecognitionEvent,
} from 'expo-speech-recognition';
import { colors, spacing, radius } from '../../../src/theme/colors';
import { Recipe } from '../../../src/types/recipe';
import { sendRecipeEditRequest } from '../../../src/services/gptService';

const SCREEN_WIDTH = Dimensions.get('window').width;

interface IngredientEdit {
  name: string;
  quantity: string;
  isModified: boolean;
}

interface MethodEdit {
  describe: string;
  isModified: boolean;
}

export default function RecipeEditPage() {
  const { recipe: recipeJson } = useLocalSearchParams<{ recipe: string }>();

  const originalRecipe = useRef<Recipe | null>(null);
  const [currentRecipe, setCurrentRecipe] = useState<Recipe | null>(null);
  const [editableIngredients, setEditableIngredients] = useState<IngredientEdit[]>([]);
  const [editableMethods, setEditableMethods] = useState<MethodEdit[]>([]);

  const [showOriginal, setShowOriginal] = useState(false);
  const [showRecipeDetails, setShowRecipeDetails] = useState(false);
  const [notes, setNotes] = useState('');
  const [capturedImages, setCapturedImages] = useState<string[]>([]);
  const [isListening, setIsListening] = useState(false);
  const [speechAvailable, setSpeechAvailable] = useState(false);
  const [isGptLoading, setIsGptLoading] = useState(false);
  const [currentImageIndex, setCurrentImageIndex] = useState(0);
  const manualStopRef = useRef(false);

  // Parse recipe from params
  useEffect(() => {
    try {
      const recipe: Recipe = recipeJson ? JSON.parse(recipeJson) : null;
      if (recipe) {
        originalRecipe.current = recipe;
        setCurrentRecipe(recipe);
        initEditableLists(recipe);
      }
    } catch {
      // invalid json
    }
  }, [recipeJson]);

  // Check speech availability
  useEffect(() => {
    (async () => {
      const result = await ExpoSpeechRecognitionModule.getPermissionsAsync();
      setSpeechAvailable(true);
    })();
  }, []);

  // Speech recognition events
  useSpeechRecognitionEvent('start', () => setIsListening(true));
  useSpeechRecognitionEvent('end', () => {
    setIsListening(false);
    // Only auto-process GPT if user manually tapped stop (matches Flutter manualStop guard)
    if (!manualStopRef.current) return;
    manualStopRef.current = false;
  });
  useSpeechRecognitionEvent('result', (event) => {
    const transcript = event.results[0]?.transcript ?? '';
    if (transcript) {
      setNotes((prev) => (prev ? `${prev} ${transcript}` : transcript));
    }
  });
  useSpeechRecognitionEvent('error', (event) => {
    console.warn('Speech error:', event.error, event.message);
    setIsListening(false);
  });

  function initEditableLists(recipe: Recipe) {
    setEditableIngredients(
      recipe.ingredients.map((i) => ({
        name: i.name,
        quantity: i.quantity,
        isModified: false,
      })),
    );
    setEditableMethods(
      recipe.methods.map((m) => ({
        describe: m.describe,
        isModified: false,
      })),
    );
  }

  function applyRecipeUpdate(updated: Recipe) {
    setCurrentRecipe(updated);
    initEditableLists(updated);
  }

  // ── Voice ──

  const startListening = useCallback(async () => {
    if (isListening) return;

    const result = await ExpoSpeechRecognitionModule.requestPermissionsAsync();
    if (!result.granted) {
      Alert.alert('권한 필요', '음성 인식을 사용하려면 마이크 권한이 필요합니다.');
      return;
    }

    ExpoSpeechRecognitionModule.start({
      lang: 'ko-KR',
      interimResults: false,
      continuous: true,
    });
  }, [isListening]);

  const stopListeningAndProcess = useCallback(async () => {
    manualStopRef.current = true;
    ExpoSpeechRecognitionModule.stop();

    // Wait a tick for final result to arrive
    setTimeout(async () => {
      const msg = notes.trim();
      if (!msg || !currentRecipe) return;

      setIsGptLoading(true);
      const updated = await sendRecipeEditRequest(currentRecipe, msg);
      setIsGptLoading(false);

      if (updated) {
        applyRecipeUpdate(updated);
        setNotes('');
        Alert.alert('완료', '레시피가 음성 명령에 따라 업데이트되었습니다!');
      } else {
        Alert.alert('오류', '레시피 업데이트에 실패했습니다.');
      }
    }, 500);
  }, [notes, currentRecipe]);

  // ── Text submit (fallback) ──

  const handleTextSubmit = useCallback(async () => {
    const msg = notes.trim();
    if (!msg || !currentRecipe) return;

    setIsGptLoading(true);
    const updated = await sendRecipeEditRequest(currentRecipe, msg);
    setIsGptLoading(false);

    if (updated) {
      applyRecipeUpdate(updated);
      setNotes('');
      Alert.alert('완료', '레시피가 텍스트 명령에 따라 업데이트되었습니다!');
    } else {
      Alert.alert('오류', '레시피 업데이트에 실패했습니다.');
    }
  }, [notes, currentRecipe]);

  // ── Ingredient / Method editing ──

  const updateIngredient = (index: number, field: 'name' | 'quantity', value: string) => {
    setEditableIngredients((prev) => {
      const copy = [...prev];
      copy[index] = { ...copy[index], [field]: value, isModified: true };
      return copy;
    });
  };

  const removeIngredient = (index: number) => {
    setEditableIngredients((prev) => prev.filter((_, i) => i !== index));
  };

  const addIngredient = () => {
    setEditableIngredients((prev) => [
      ...prev,
      { name: '', quantity: '', isModified: true },
    ]);
  };

  const updateMethod = (index: number, value: string) => {
    setEditableMethods((prev) => {
      const copy = [...prev];
      copy[index] = { ...copy[index], describe: value, isModified: true };
      return copy;
    });
  };

  const removeMethod = (index: number) => {
    setEditableMethods((prev) => prev.filter((_, i) => i !== index));
  };

  const addMethod = () => {
    setEditableMethods((prev) => [
      ...prev,
      { describe: '', isModified: true },
    ]);
  };

  const insertMethodAt = (index: number) => {
    setEditableMethods((prev) => {
      const copy = [...prev];
      copy.splice(index, 0, { describe: '', isModified: true });
      return copy;
    });
  };

  // ── Image picking ──

  const pickImages = async () => {
    const result = await ImagePicker.launchImageLibraryAsync({
      mediaTypes: ['images'],
      allowsMultipleSelection: true,
      quality: 0.8,
    });
    if (!result.canceled) {
      setCapturedImages((prev) => [
        ...prev,
        ...result.assets.map((a) => a.uri),
      ]);
    }
  };

  const takePhoto = async () => {
    const perm = await ImagePicker.requestCameraPermissionsAsync();
    if (!perm.granted) {
      Alert.alert('권한 필요', '카메라 사용 권한이 필요합니다.');
      return;
    }
    const result = await ImagePicker.launchCameraAsync({
      quality: 0.8,
    });
    if (!result.canceled) {
      setCapturedImages((prev) => [...prev, result.assets[0].uri]);
    }
  };

  const removeImage = (index: number) => {
    setCapturedImages((prev) => prev.filter((_, i) => i !== index));
    if (currentImageIndex >= capturedImages.length - 1 && currentImageIndex > 0) {
      setCurrentImageIndex(currentImageIndex - 1);
    }
  };

  // ── Submit post ──

  const buildPostContent = (): string => {
    const parts: string[] = [];

    if (currentRecipe) {
      parts.push(`레시피: ${currentRecipe.title}\n`);
    }

    const modIng = editableIngredients.filter((i) => i.isModified);
    if (modIng.length > 0) {
      parts.push('[재료 수정]');
      modIng.forEach((i) => parts.push(`• ${i.name}: ${i.quantity}`));
      parts.push('');
    }

    const modMeth = editableMethods.filter((m) => m.isModified);
    if (modMeth.length > 0) {
      parts.push('[조리법 수정]');
      modMeth.forEach((m, i) => parts.push(`${i + 1}. ${m.describe}`));
      parts.push('');
    }

    if (notes.trim()) {
      parts.push('[요리 후기]');
      parts.push(notes.trim());
    }

    return parts.join('\n');
  };

  const handleSubmit = () => {
    if (capturedImages.length === 0) {
      Alert.alert('사진 필요', '요리한 음식 사진을 최소 1장 추가해주세요.');
      return;
    }

    const content = buildPostContent();

    router.push({
      pathname: '/(tabs)/create/confirm',
      params: {
        imageUris: JSON.stringify(capturedImages),
        category: '요리',
        review: 'Recipe',
        content,
        capturedDate: new Date().toISOString(),
        recommendRecipe: 'true',
        mealKitLink: '',
        restaurantName: '',
        deliveryLink: '',
      },
    });
  };

  // ── Error state ──

  if (!currentRecipe) {
    return (
      <View style={styles.center}>
        <Text style={styles.errorText}>레시피를 불러올 수 없습니다.</Text>
        <TouchableOpacity onPress={() => router.back()}>
          <Text style={styles.backLink}>뒤로 가기</Text>
        </TouchableOpacity>
      </View>
    );
  }

  // ── Original recipe view ──

  const renderOriginalView = () => (
    <ScrollView contentContainerStyle={styles.scrollContent}>
      {originalRecipe.current?.images.originalUrl ? (
        <Image
          source={{ uri: originalRecipe.current.images.originalUrl }}
          style={styles.mainImage}
        />
      ) : null}

      <View style={styles.section}>
        <Text style={styles.recipeTitle}>{originalRecipe.current?.title}</Text>
      </View>

      {originalRecipe.current?.tips ? (
        <View style={styles.section}>
          <View style={styles.tipsRow}>
              <Ionicons name="bulb-outline" size={14} color="#9E9E9E" />
              <Text style={styles.tipsText}>{originalRecipe.current.tips}</Text>
            </View>
        </View>
      ) : null}

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>재료</Text>
        <View style={styles.dividerLine} />
        {originalRecipe.current?.ingredients.map((ing, i) => (
          <Text key={i} style={styles.ingredientText}>
            • {ing.name}: {ing.quantity}
          </Text>
        ))}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>조리법</Text>
        <View style={styles.dividerLine} />
        {originalRecipe.current?.methods.map((method, i) => (
          <View key={i} style={{ marginBottom: spacing.md }}>
            <Text style={styles.methodStepLabel}>{i + 1}. {method.describe}</Text>
            {method.image?.originalUrl ? (
              <Image
                source={{ uri: method.image.originalUrl }}
                style={styles.methodImage}
              />
            ) : null}
          </View>
        ))}
      </View>

      <View style={{ height: 100 }} />
    </ScrollView>
  );

  // ── Edit view ──

  const renderEditView = () => (
    <ScrollView contentContainerStyle={styles.scrollContent}>
      {/* Collapsible recipe info card */}
      <Pressable
        onPress={() => setShowRecipeDetails(!showRecipeDetails)}
        style={styles.recipeInfoCard}
      >
        <View style={styles.recipeInfoHeader}>
          <Ionicons name="book-outline" size={20} color={colors.primary} />
          <Text style={styles.recipeInfoTitle} numberOfLines={1}>
            {currentRecipe.title}
          </Text>
          <Ionicons
            name={showRecipeDetails ? 'chevron-up' : 'chevron-down'}
            size={20}
            color={colors.hint}
          />
        </View>
        {currentRecipe.tips ? (
          <View style={styles.cardTipsRow}>
            <Ionicons name="bulb-outline" size={12} color="#9E9E9E" />
            <Text style={styles.recipeInfoTips} numberOfLines={2}>
              {currentRecipe.tips}
            </Text>
          </View>
        ) : null}
      </Pressable>

      {showRecipeDetails && (
        <View style={styles.editSection}>
          {/* Ingredients edit */}
          <View style={styles.editSectionHeader}>
            <View style={styles.editSectionLeft}>
              <Ionicons name="restaurant-outline" size={18} color={colors.primary} />
              <Text style={styles.editSectionTitle}>Ingredients</Text>
            </View>
            <TouchableOpacity onPress={addIngredient}>
              <Ionicons name="add-circle-outline" size={22} color={colors.primary} />
            </TouchableOpacity>
          </View>
          <View style={styles.gradientLine} />

          {/* Ingredient list */}
          <View style={styles.ingredientsGrid}>
            {editableIngredients.map((ing, index) => (
              <View
                key={`ing-${index}`}
                style={[
                  styles.ingredientEditItem,
                  ing.isModified && styles.ingredientModified,
                ]}
              >
                <View style={styles.ingredientBullet}>
                  <View
                    style={[
                      styles.bullet,
                      ing.isModified && styles.bulletModified,
                    ]}
                  />
                </View>
                <View style={styles.ingredientFields}>
                  <TextInput
                    style={[
                      styles.ingNameInput,
                      ing.isModified && styles.ingNameModified,
                    ]}
                    value={ing.name}
                    onChangeText={(v) => updateIngredient(index, 'name', v)}
                    placeholder="ingredient"
                    placeholderTextColor="#757575"
                  />
                  <Text style={styles.ingDivider}>|</Text>
                  <TextInput
                    style={styles.ingQuantityInput}
                    value={ing.quantity}
                    onChangeText={(v) => updateIngredient(index, 'quantity', v)}
                    placeholder="amount"
                    placeholderTextColor="#757575"
                  />
                </View>
                <TouchableOpacity onPress={() => removeIngredient(index)}>
                  <Ionicons name="close" size={16} color="#757575" />
                </TouchableOpacity>
              </View>
            ))}
          </View>

          {/* Methods edit */}
          <View style={[styles.editSectionHeader, { marginTop: spacing.lg }]}>
            <View style={styles.editSectionLeft}>
              <Ionicons name="flame-outline" size={18} color={colors.primary} />
              <Text style={styles.editSectionTitle}>Directions</Text>
            </View>
            <TouchableOpacity onPress={addMethod}>
              <Ionicons name="add-circle-outline" size={22} color={colors.primary} />
            </TouchableOpacity>
          </View>
          <View style={styles.gradientLine} />

          {editableMethods.map((method, index) => (
            <View key={`method-${index}`}>
              <View
                style={[
                  styles.methodEditItem,
                  method.isModified && styles.methodModified,
                ]}
              >
                <Text
                  style={[
                    styles.methodStepNum,
                    method.isModified && styles.methodStepNumModified,
                  ]}
                >
                  {index + 1}.
                </Text>
                <TextInput
                  style={[
                    styles.methodInput,
                    method.isModified && styles.methodInputModified,
                  ]}
                  value={method.describe}
                  onChangeText={(v) => updateMethod(index, v)}
                  multiline
                  placeholder="Describe this step..."
                  placeholderTextColor="#757575"
                />
                <TouchableOpacity onPress={() => removeMethod(index)}>
                  <Ionicons name="close" size={20} color="#757575" />
                </TouchableOpacity>
              </View>

              {/* Insert divider between methods */}
              {index < editableMethods.length - 1 && (
                <Pressable
                  onPress={() => insertMethodAt(index + 1)}
                  style={styles.insertDivider}
                >
                  <View style={styles.insertLine} />
                  <Ionicons
                    name="add-circle-outline"
                    size={16}
                    color="rgba(255,255,255,0.3)"
                  />
                  <View style={styles.insertLine} />
                </Pressable>
              )}
            </View>
          ))}
        </View>
      )}

      {/* Voice input section */}
      <View style={styles.voiceSection}>
        <TouchableOpacity
          onPress={isListening ? stopListeningAndProcess : startListening}
          style={[styles.micButton, isListening && styles.micButtonActive]}
          activeOpacity={0.7}
        >
          <Ionicons
            name={isListening ? 'mic' : 'mic-outline'}
            size={isListening ? 50 : 40}
            color="#FFFFFF"
          />
        </TouchableOpacity>
        <View style={styles.voiceLabelRow}>
          <Text style={[styles.voiceLabel, isListening && styles.voiceLabelActive]}>
            {isListening ? '듣는 중... 탭하여 중지' : '탭하여 음성으로 입력'}
          </Text>
          {!isListening && (
            <>
              <Text style={styles.voiceDivider}>|</Text>
              <Pressable onPress={() => setNotes((p) => p || ' ')}>
                <Text style={styles.manualLabel}>직접 입력</Text>
              </Pressable>
            </>
          )}
        </View>
      </View>

      {/* GPT loading indicator */}
      {isGptLoading && (
        <View style={styles.gptLoading}>
          <ActivityIndicator size="small" color="#C7F464" />
          <Text style={styles.gptLoadingText}>레시피 개선 요청 중...</Text>
        </View>
      )}

      {/* Text input (shown when notes exist or voice unavailable) */}
      {(notes.length > 0 || !speechAvailable) && (
        <View style={styles.notesSection}>
          <TextInput
            style={styles.notesInput}
            value={notes}
            onChangeText={setNotes}
            multiline
            numberOfLines={5}
            placeholder="요리하면서 느낀 점, 맛 평가, 팁 등을 자유롭게 작성해주세요."
            placeholderTextColor="rgba(255,255,255,0.4)"
            onSubmitEditing={handleTextSubmit}
          />
          <TouchableOpacity style={styles.sendBtn} onPress={handleTextSubmit}>
            <Ionicons name="send" size={18} color={colors.onPrimary} />
          </TouchableOpacity>
        </View>
      )}

      {/* Image picker section */}
      <View style={styles.imageSection}>
        {capturedImages.length === 0 ? (
          <View style={styles.imageEmptyContainer}>
            <TouchableOpacity style={styles.imagePickBtn} onPress={pickImages}>
              <Ionicons name="camera-outline" size={48} color="#757575" />
              <Text style={styles.imagePickText}>요리 완성 사진 추가</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.imagePickBtn} onPress={takePhoto}>
              <Ionicons name="camera" size={48} color="#757575" />
              <Text style={styles.imagePickText}>사진 촬영</Text>
            </TouchableOpacity>
          </View>
        ) : (
          <View style={styles.imageCarouselWrap}>
            <FlatList
              data={capturedImages}
              horizontal
              pagingEnabled
              showsHorizontalScrollIndicator={false}
              onMomentumScrollEnd={(e) => {
                const idx = Math.round(
                  e.nativeEvent.contentOffset.x / (SCREEN_WIDTH - 32),
                );
                setCurrentImageIndex(idx);
              }}
              renderItem={({ item }) => (
                <Image
                  source={{ uri: item }}
                  style={styles.carouselImage}
                />
              )}
              keyExtractor={(item, i) => `${item}-${i}`}
            />
            <View style={styles.imageActions}>
              <TouchableOpacity style={styles.imageActionBtn} onPress={pickImages}>
                <Ionicons name="add" size={20} color="#fff" />
              </TouchableOpacity>
              <TouchableOpacity style={styles.imageActionBtn} onPress={takePhoto}>
                <Ionicons name="camera" size={20} color="#fff" />
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.imageActionBtn}
                onPress={() => removeImage(currentImageIndex)}
              >
                <Ionicons name="close" size={20} color="#fff" />
              </TouchableOpacity>
            </View>
            {capturedImages.length > 1 && (
              <View style={styles.dots}>
                {capturedImages.map((_, i) => (
                  <View
                    key={i}
                    style={[
                      styles.dot,
                      i === currentImageIndex && styles.dotActive,
                    ]}
                  />
                ))}
              </View>
            )}
          </View>
        )}
      </View>

      <View style={{ height: 100 }} />
    </ScrollView>
  );

  // ── Main render ──

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()}>
          <Ionicons name="arrow-back" size={24} color={colors.primary} />
        </TouchableOpacity>
        <Text style={styles.headerTitle}>요리 기록하기</Text>
        <TouchableOpacity onPress={() => setShowOriginal(!showOriginal)}>
          <Ionicons
            name={showOriginal ? 'create-outline' : 'book-outline'}
            size={24}
            color={colors.primary}
          />
        </TouchableOpacity>
      </View>

      {showOriginal ? renderOriginalView() : renderEditView()}

      {/* Bottom submit button */}
      <View style={styles.bottomBar}>
        <TouchableOpacity style={styles.submitBtn} onPress={handleSubmit}>
          <Text style={styles.submitText}>게시글 작성 완료</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: colors.bgLight },
  center: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.bgLight,
  },
  scrollContent: { paddingTop: 8, paddingHorizontal: spacing.sm },

  // Header
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: spacing.md,
    paddingTop: 60,
    paddingBottom: spacing.sm,
  },
  headerTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: colors.primary,
  },

  // Original view — borderRadius 12 matching Flutter
  mainImage: {
    width: '100%',
    height: 200,
    borderRadius: 12,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },
  section: {
    paddingTop: spacing.lg,
  },
  recipeTitle: {
    fontSize: 24,
    fontWeight: '700',
    color: colors.primary,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: '700',
    color: colors.primary,
    marginBottom: spacing.xs,
  },
  dividerLine: {
    height: 1,
    backgroundColor: colors.divider,
    marginBottom: spacing.sm,
  },
  tipsRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 6,
    backgroundColor: 'rgba(255,165,0,0.1)',
    padding: spacing.md,
    borderRadius: radius.sm,
  },
  tipsText: {
    flex: 1,
    fontSize: 15,
    color: colors.primary,
    fontStyle: 'italic',
    lineHeight: 22,
  },
  ingredientText: {
    fontSize: 15,
    color: colors.primary,
    lineHeight: 24,
  },
  methodStepLabel: {
    fontSize: 16,
    color: colors.primary,
    lineHeight: 24,
  },
  methodImage: {
    width: '100%',
    height: 180,
    borderRadius: radius.sm,
    marginTop: spacing.sm,
    backgroundColor: 'rgba(255,255,255,0.08)',
  },

  // Recipe info card — bg grey[900], borderRadius 12 matching Flutter
  recipeInfoCard: {
    backgroundColor: '#212121',
    borderRadius: 12,
    padding: spacing.sm,
  },
  recipeInfoHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  recipeInfoTitle: {
    flex: 1,
    fontSize: 16,
    fontWeight: '600',
    color: colors.primary,
  },
  cardTipsRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 4,
    marginTop: 8,
  },
  recipeInfoTips: {
    flex: 1,
    fontSize: 12,
    color: '#9E9E9E',
    fontStyle: 'italic',
  },

  // Edit section
  editSection: {
    marginTop: spacing.md,
  },
  editSectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  editSectionLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  editSectionTitle: {
    fontSize: 18,
    fontWeight: '700',
    color: colors.primary,
    letterSpacing: 0.5,
  },
  gradientLine: {
    height: 2,
    backgroundColor: colors.primary,
    marginVertical: spacing.sm,
    opacity: 0.3,
  },

  // Ingredients grid
  ingredientsGrid: {
    gap: 4,
  },
  ingredientEditItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 4,
    paddingVertical: 2,
  },
  ingredientModified: {
    backgroundColor: 'rgba(255,191,0,0.05)',
  },
  ingredientBullet: {
    paddingTop: 8,
    paddingRight: 8,
  },
  bullet: {
    width: 4,
    height: 4,
    borderRadius: 2,
    backgroundColor: '#9E9E9E',
  },
  bulletModified: {
    backgroundColor: '#FFB300',
  },
  ingredientFields: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
  },
  ingNameInput: {
    flex: 2,
    fontSize: 14,
    color: '#E0E0E0',
    fontWeight: '500',
    padding: 0,
  },
  ingNameModified: {
    color: 'rgba(255,191,0,0.8)',
  },
  ingDivider: {
    fontSize: 14,
    color: '#757575',
    marginHorizontal: 6,
  },
  ingQuantityInput: {
    flex: 1,
    fontSize: 14,
    color: '#BDBDBD',
    padding: 0,
  },

  // Methods edit
  methodEditItem: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    paddingHorizontal: 4,
    paddingVertical: 6,
    marginBottom: 4,
  },
  methodModified: {
    backgroundColor: 'rgba(255,69,0,0.05)',
  },
  methodStepNum: {
    fontSize: 15,
    fontWeight: '700',
    color: '#BDBDBD',
    paddingTop: 4,
    paddingRight: 4,
    lineHeight: 24,
  },
  methodStepNumModified: {
    color: '#FF8A00',
  },
  methodInput: {
    flex: 1,
    fontSize: 15,
    color: '#E0E0E0',
    lineHeight: 24,
    padding: 0,
  },
  methodInputModified: {
    color: 'rgba(255,140,0,0.8)',
  },
  insertDivider: {
    flexDirection: 'row',
    alignItems: 'center',
    height: 24,
    gap: 8,
  },
  insertLine: {
    flex: 1,
    height: 1,
    backgroundColor: '#616161',
  },

  // Voice section — colors matching Flutter gradient
  voiceSection: {
    alignItems: 'center',
    marginTop: spacing.lg,
  },
  micButton: {
    width: 100,
    height: 100,
    borderRadius: 50,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#616161',
    shadowColor: '#000000',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.3,
    shadowRadius: 10,
    elevation: 4,
  },
  micButtonActive: {
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: '#7C4DFF',
    shadowColor: '#448AFF',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.4,
    shadowRadius: 20,
    elevation: 10,
  },
  voiceLabelRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: spacing.sm,
    gap: 8,
  },
  voiceLabel: {
    fontSize: 14,
    color: '#9E9E9E',
  },
  voiceLabelActive: {
    color: '#82B1FF',
    fontWeight: '600',
  },
  voiceDivider: {
    color: 'rgba(255,255,255,0.3)',
  },
  manualLabel: {
    fontSize: 14,
    color: '#9E9E9E',
  },

  // GPT loading
  gptLoading: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    marginTop: spacing.md,
  },
  gptLoadingText: {
    fontSize: 14,
    color: '#C7F464',
  },

  // Notes
  notesSection: {
    marginTop: spacing.md,
    position: 'relative',
  },
  notesInput: {
    backgroundColor: '#212121',
    borderRadius: 12,
    padding: spacing.md,
    paddingRight: 48,
    color: colors.primary,
    fontSize: 15,
    minHeight: 100,
    textAlignVertical: 'top',
  },
  sendBtn: {
    position: 'absolute',
    right: 8,
    bottom: 8,
    backgroundColor: colors.primary,
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
  },

  // Image section
  imageSection: {
    marginTop: spacing.md,
  },
  imageEmptyContainer: {
    flexDirection: 'row',
    gap: spacing.sm,
  },
  imagePickBtn: {
    flex: 1,
    height: 200,
    backgroundColor: '#212121',
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#616161',
    justifyContent: 'center',
    alignItems: 'center',
    gap: 8,
  },
  imagePickText: {
    fontSize: 13,
    color: '#757575',
  },
  imageCarouselWrap: {
    height: 200,
    borderRadius: 12,
    overflow: 'hidden',
    backgroundColor: 'rgba(255,255,255,0.05)',
  },
  carouselImage: {
    width: SCREEN_WIDTH - 32,
    height: 200,
  },
  imageActions: {
    position: 'absolute',
    top: 8,
    right: 8,
    flexDirection: 'row',
    gap: 8,
  },
  imageActionBtn: {
    backgroundColor: 'rgba(0,0,0,0.5)',
    width: 36,
    height: 36,
    borderRadius: 18,
    justifyContent: 'center',
    alignItems: 'center',
  },
  dots: {
    position: 'absolute',
    bottom: 8,
    left: 0,
    right: 0,
    flexDirection: 'row',
    justifyContent: 'center',
    gap: 8,
  },
  dot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    backgroundColor: 'rgba(255,255,255,0.4)',
  },
  dotActive: {
    backgroundColor: 'rgba(255,255,255,0.9)',
  },

  // Bottom bar
  bottomBar: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    paddingHorizontal: spacing.md,
    paddingTop: spacing.sm,
    paddingBottom: 34,
    backgroundColor: 'rgba(15,17,21,0.95)',
    borderTopWidth: StyleSheet.hairlineWidth,
    borderTopColor: colors.divider,
  },
  submitBtn: {
    backgroundColor: colors.primary,
    paddingVertical: 16,
    borderRadius: 12,
    alignItems: 'center',
  },
  submitText: {
    fontSize: 16,
    fontWeight: '600',
    color: colors.onPrimary,
  },

  // Error
  errorText: {
    fontSize: 16,
    color: colors.hint,
    marginBottom: spacing.sm,
  },
  backLink: {
    fontSize: 14,
    color: '#C7F464',
  },
});
